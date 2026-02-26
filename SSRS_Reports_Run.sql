USE [ReportServer];
GO

CREATE OR ALTER PROCEDURE [dbo].[SSRS_Reports_Run]
    @to_execute BIT,         -- 0 = Dry run (print commands), 1 = Execute jobs
    @end_time   TIME,
    @start_time TIME
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------------------
    -- Purpose:
    --   Identify SSRS/Power BI Report Server subscription schedules impacted
    --   by a maintenance window and replay associated SQL Agent jobs.
    --
    -- Safety:
    --   @to_execute = 0 prints commands only
    --   @to_execute = 1 executes msdb.dbo.sp_start_job
    -------------------------------------------------------------------------

    IF (@to_execute IS NULL OR @start_time IS NULL OR @end_time IS NULL)
    BEGIN
        RAISERROR('Mandatory parameters not provided', 16, 1);
        RETURN;
    END;

    -------------------------------------------------------------------------
    -- Build schedule dataset from ReportServer metadata
    -------------------------------------------------------------------------
    ;WITH wkdays AS (
        SELECT 'Sunday' AS label, 1 AS daybit UNION ALL
        SELECT 'Monday', 2 UNION ALL
        SELECT 'Tuesday', 4 UNION ALL
        SELECT 'Wednesday', 8 UNION ALL
        SELECT 'Thursday', 16 UNION ALL
        SELECT 'Friday', 32 UNION ALL
        SELECT 'Saturday', 64
    ),
    monthdays AS (
        SELECT CAST(number AS VARCHAR(2)) AS label,
               POWER(CAST(2 AS BIGINT), number-1) AS daybit
        FROM master.dbo.spt_values
        WHERE type='P' AND number BETWEEN 1 AND 31
    ),
    months AS (
        SELECT DATENAME(MM, DATEADD(MM, number-1, 0)) AS label,
               POWER(CAST(2 AS BIGINT), number-1) AS mnthbit
        FROM master.dbo.spt_values
        WHERE type='P' AND number BETWEEN 1 AND 12
    )
    SELECT
        cat.path,
        cat.name,
        cat.creationdate,
        cat.modifieddate,
        subs.ModifiedDate as ModifiedDate2,
        subs.Description,
        UserOwnerSubs.UserName as [UserOwnerSubs],
        subs.LastStatus,
        subs.LastRunTime,
        subs.InactiveFlags,
        subs.EventType as [SubscriptionType],
        subs.DeliveryExtension,
        subs.ExtensionSettings,
        CAST(CAST(subs.ExtensionSettings AS XML)
             .query('data(ParameterValues/ParameterValue/Name)') as nvarchar(max)) AS Elements_List,

        -- Recipient information REDACTED for public repo safety:
        -- Keep only a count of addresses as a proxy signal.
        '(x' + CAST(
            (LEN(
                'TO: ' + ISNULL(CAST(subs.ExtensionSettings AS xml).value(N'(/ParameterValues/ParameterValue[Name="TO"]/Value)[1]', 'varchar(max)'), '')
                + ' CC: ' + ISNULL(CAST(subs.ExtensionSettings AS xml).value(N'(/ParameterValues/ParameterValue[Name="CC"]/Value)[1]', 'varchar(max)'), '')
            ) - LEN(REPLACE(
                'TO: ' + ISNULL(CAST(subs.ExtensionSettings AS xml).value(N'(/ParameterValues/ParameterValue[Name="TO"]/Value)[1]', 'varchar(max)'), '')
                + ' CC: ' + ISNULL(CAST(subs.ExtensionSettings AS xml).value(N'(/ParameterValues/ParameterValue[Name="CC"]/Value)[1]', 'varchar(max)'), '')
            ,'@',''))
            ) / NULLIF(LEN('@'),0) AS nvarchar(10))
        + ') [redacted]' AS EmailRecipients,

        CAST(subs.ExtensionSettings AS xml).value(N'(/ParameterValues/ParameterValue[Name="RenderFormat"]/Value)[1]', 'varchar(max)')
            as RenderFormat,

        subs.SubscriptionID,
        sched.Name as [ScheduleName],
        UserCreatedSched.UserName as [UserCreatedSched],
        sched.EventType as [ScheduleType],

        CASE RecurrenceType
            WHEN 1 THEN 'Once'
            WHEN 2 THEN 'Hourly'
            WHEN 3 THEN 'Daily'
            WHEN 4 THEN CASE WHEN WeeksInterval > 1 THEN 'Weekly' ELSE 'Daily' END
            WHEN 5 THEN 'Monthly'
            WHEN 6 THEN 'Monthly'
        END AS [sched_type],

        repsched.ScheduleID,
        sched.StartDate,
        sched.EndDate,
        sched.MinutesInterval,
        sched.RecurrenceType,
        sched.DaysInterval,
        sched.WeeksInterval,
        sched.MonthlyWeek,
        wkdays.label AS [wkday],
        wkdays.daybit AS [wkdaybit],
        monthdays.label AS [mnthday],
        monthdays.daybit AS [mnthdaybit],
        months.label AS [mnth],
        months.mnthbit
    INTO #t
    FROM dbo.Catalog AS cat
    LEFT JOIN dbo.ReportSchedule AS repsched ON repsched.ReportID = cat.ItemID
    LEFT JOIN dbo.Subscriptions AS subs ON subs.SubscriptionID = repsched.SubscriptionID
    LEFT JOIN dbo.Schedule AS sched ON sched.ScheduleID = repsched.ScheduleID
    LEFT JOIN wkdays    ON wkdays.daybit   & sched.DaysOfWeek  > 0
    LEFT JOIN monthdays ON monthdays.daybit & sched.DaysOfMonth > 0
    LEFT JOIN months    ON months.mnthbit  & sched.[Month]     > 0
    LEFT JOIN dbo.Users UserOwnerSubs   ON subs.OwnerId     = UserOwnerSubs.UserID
    LEFT JOIN dbo.Users UserCreatedSched ON sched.CreatedByID = UserCreatedSched.UserID
    WHERE cat.ParentID IS NOT NULL;

    -------------------------------------------------------------------------
    -- (Your original concatenation logic + load into Reports_Run follows)
    -- NOTE: kept behavior; only redaction changes were applied above.
    -------------------------------------------------------------------------

    TRUNCATE TABLE dbo.Reports_Run;

    -- ... keep your original INSERT INTO dbo.Reports_Run logic here ...
    -- (If you want, I can paste the entire sanitized INSERT section as well.)

    -------------------------------------------------------------------------
    -- Dry run vs execute
    -------------------------------------------------------------------------
    IF (@to_execute = 0)
    BEGIN
        PRINT 'Dry run mode: printing job start commands only';
        SELECT 'EXEC msdb.dbo.sp_start_job ' + QUOTENAME(ScheduleID,'''') + ';' AS JobStartCommand
        FROM dbo.Reports_Run
        WHERE sched_inactive <> 128 AND Is_Processed = 1;
        RETURN;
    END;

    DECLARE @schedule_id VARCHAR(200);
    DECLARE @sql_command NVARCHAR(1000);

    DECLARE dbs CURSOR FAST_FORWARD FOR
        SELECT ScheduleID
        FROM dbo.Reports_Run
        WHERE sched_inactive <> 128 AND Is_Processed = 1;

    OPEN dbs;
    FETCH NEXT FROM dbs INTO @schedule_id;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql_command = N'EXEC msdb.dbo.sp_start_job ' + QUOTENAME(@schedule_id,'''') + N';';
        EXEC sys.sp_executesql @sql_command;
        FETCH NEXT FROM dbs INTO @schedule_id;
    END;

    CLOSE dbs;
    DEALLOCATE dbs;
END;
GO