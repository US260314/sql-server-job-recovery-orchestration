USE [DBA_Maintenance];
GO

CREATE OR ALTER PROCEDURE [dbo].[usp_patch_maintenance]
    @maintenance_start_time TIME = '01:00:00',
    @to_execute BIT = 0, -- 0=dry run for SSRS replay, 1=execute SSRS replay
    @agent_service_display_name SYSNAME = N'SQL Server Agent (MSSQLSERVER)'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @service_status VARCHAR(500);
    DECLARE @service_startup_type VARCHAR(500);

    SELECT @service_status = status_desc
    FROM sys.dm_server_services
    WHERE servicename = @agent_service_display_name;

    SELECT @service_startup_type = startup_type_desc
    FROM sys.dm_server_services
    WHERE servicename = @agent_service_display_name;

    -- Log current state (table should exist; see dependency section)
    INSERT INTO dbo.Patch_Maintenance_Tasks (Task_Name, Task_Status_Outcome, LogDate)
    VALUES ('SQLAgent Service Check',
            CONCAT('Status=', ISNULL(@service_status,'Unknown'), '; StartupType=', ISNULL(@service_startup_type,'Unknown')),
            GETDATE());

    -- NOTE:
    -- Your original procedure uses xp_cmdshell to modify/start the service.
    -- That requires sysadmin and increases risk. Prefer infra-managed service
    -- startup + SQL Agent job triggered at startup to run recovery.

    DECLARE @service_end_time TIME;

    SELECT @service_end_time = CONVERT(TIME, last_startup_time)
    FROM sys.dm_server_services
    WHERE servicename = @agent_service_display_name;

    INSERT INTO dbo.Patch_Maintenance_Tasks (Task_Name, Task_Status_Outcome, LogDate)
    VALUES ('Trigger SSRS Replay',
            CONCAT('Calling ReportServer.dbo.SSRS_Reports_Run with window ',
                   'Start=', CONVERT(VARCHAR(8), @maintenance_start_time, 108),
                   ' End=',   CONVERT(VARCHAR(8), @service_end_time, 108),
                   ' to_execute=', @to_execute),
            GETDATE());

    EXEC ReportServer.dbo.SSRS_Reports_Run
         @to_execute = @to_execute,
         @start_time = @maintenance_start_time,
         @end_time   = @service_end_time;
END;
GO