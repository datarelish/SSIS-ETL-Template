/**********************************************************************************************
Procedure Name:audit.up_Event_Package_OnBegin
Description: This stored procedure logs a starting event to the custom event-log table
Parameters :
@ParentLogID int
,@Description varchar(50) = null
,@PackageName varchar(50)
,@PackageGuid uniqueidentifier
,@MachineName varchar(50)
,@ExecutionGuid uniqueidentifier
,@logicalDate datetime
,@operator varchar(30)
,@logID int = null output
Example:
declare @logID int
exec audit.up_Event_Package_OnBegin 3, 'Description'
,'PackageName' ,'00000000-0000-0000-0000-000000000000'
,'MachineName’', '00000000-0000-0000-0000-000000000000'
,'2019-05-01 00:00:000', 'operator', 3
--null 

select * from [audit].[ETL_ExecutionLog] 

Author: Jen Stirrup
Date: 22nd May 2019


 
**********************************************************************************************/


PRINT N'Creating [Audit].[up_Event_Package_OnBegin]'
GO
ALTER procedure [Audit].[up_Event_Package_OnBegin]
@ParentLogID int
,@Description varchar(50) = null
,@PackageName varchar(50)
,@PackageGuid uniqueidentifier
,@MachineName varchar(50)
,@ExecutionGuid uniqueidentifier
,@logicalDate datetime
,@operator varchar(30)
,@logID int = null output
with execute as caller
as

begin
set nocount on
-- Coalesce @logicalDate
set @logicalDate = isnull(@logicalDate, getdate())
-- Coalesce @operator
set @operator = nullif(ltrim(rtrim(@operator)), '')
set @operator = isnull(@operator, suser_sname())

if @ParentLogID <= 0 set @ParentLogID = null

set @Description = nullif(ltrim(rtrim(@Description)),'')


if @Description is null and @ParentLogID is null set @Description = @PackageName


-- Insert the log record
insert into [audit].[ETL_ExecutionLog](
ParentLogID
,Description
,PackageName
,PackageGuid
,MachineName
,ExecutionGuid
,LogicalDate
,Operator
,StartTime
,EndTime
,Status
,FailureTask
) values (
@ParentLogID
,@Description
,@PackageName
,@PackageGuid
,@MachineName
,@ExecutionGuid
,@logicalDate
,@operator
,getdate() -- Note: This should NOT be @logicalDate
,null
,0 -- InProcess
,null
)
 set @logID = scope_identity()
set nocount off
end -- proc
GO

/**********************************************************************************************
Procedure Name:[Audit].[up_ETL_Event_Package_OnError]
Description: This stored procedure logs an error entry in the custom event-log table.
Status = 0: Running (Incomplete)
Status = 1: Complete
Status = 2: Failed
Parameters : @ParameterName ParameterDataType Description
Example:
-- exec audit.up_Event_Package_OnError 1, 'Failed'
exec audit.up_Event_Package_OnError 2, 'Failed'
exec audit.up_Event_Package_OnError 'Failed'
select * from [audit].[ETL_ExecutionLog] where LogID = 1
select * from [audit].[ETL_ExecutionLog] where LogID = 2

Author: Jen Stirrup
Date: 22nd May 2019
 
**********************************************************************************************/

PRINT N'Creating [Audit].[up_Event_Package_OnError]'
GO
ALTER PROCEDURE [Audit].[up_Event_Package_OnError]
	--/*
	 --* log ID removed to anticipate changes in SQL Server 2017
	 @logID INT
	--,
	--*/
	,@message VARCHAR(64) = null --optional, for custom failures
WITH EXECUTE AS CALLER
AS

BEGIN
SET NOCOUNT ON
DECLARE
 @failureTask	VARCHAR(64)
,@packageName	VARCHAR(64)
,@executionGuid UNIQUEIDENTIFIER

	IF @message is null 
	BEGIN


		SELECT

		@packageName		= UPPER(PackageName)
		,@executionGuid		= ExecutionGuid
		FROM AUDIT.ExecutionLog

		WHERE LogID = @logID

		SELECT 
			TOP 1 @failureTask = source
			FROM dbo.sysdtslog90

			WHERE executionid = @executionGuid
			AND (UPPER(event) = 'ONERROR')
			AND UPPER(source) <> @packageName
			ORDER BY endtime DESC
		END 
		ELSE 
			BEGIN
			SET 
			@failureTask = @message
			END

			UPDATE [audit].[ETL_ExecutionLog] SET
			EndTime = getdate()
			,Status = 2 -- Failed
			,FailureTask = @failureTask
			WHERE
			LogID = @logID
			SET NOCOUNT OFF
	END
GO

PRINT N'Creating [Audit].[up_Event_Package_OnEnd]'
GO
CREATE procedure [Audit].[up_Event_Package_OnEnd]
@logID int
with execute as caller
as
/**********************************************************************************************
Procedure Name:[Audit].[up_Event_Package_OnEnd]
Description: This stored procedure updates an existing entry in the custom event-log table. It flags the
execution run as complete.
Status = 0: Running (Incomplete)
Status = 1: Complete
Status = 2: Failed
Parameters : @Parameter ParameterDataType Description
Example:
declare @logID int
set @logID = 0
exec audit.up_Event_Package_OnEnd @logID
exec audit.up_Event_Package_OnEnd 3
select * from [audit].[ETL_ExecutionLog] where LogID = 2

Author: Jen Stirrup
Date: 22nd May 2019
 
**********************************************************************************************/
BEGIN
SET NOCOUNT ON
UPDATE [audit].[ETL_ExecutionLog] 
SET
EndTime = getdate() -- Note: This should NOT be @logicalDate
,
STATUS = 
		CASE
		WHEN Status = 0 then 1	-- Complete
		ELSE Status
		END						-- Case
WHERE
LogID = @logID
SET NOCOUNT OFF
END -- proc

PRINT N'Creating [Audit].[up_Event_Package_OnCount]'
GO
CREATE procedure [Audit].[up_Event_Package_OnCount]
@logID INT
,@ComponentName VARCHAR(50)
,@Rows INT
,@TimeMS INT
,@MinRowsPerSec INT = null
,@MaxRowsPerSec INT = null
WITH EXECUTE AS CALLER
AS
/**********************************************************************************************
Procedure Name: audit.up_Event_Package_OnCount
Description: This stored procedure logs an error entry in the custom event-log table.
Status = 0: Running (Incomplete)
Status = 1: Complete
Status = 2: Failed
Parameters:
@logID int
,@ComponentName varchar(50)
,@Rows int
,@TimeMS int
,@MinRowsPerSec int = null
,@MaxRowsPerSec int = null
Example:
exec audit.up_Event_Package_OnCount 3, 'Test', 100, 1000, 5, 50
SELECT * FROM audit.StatisticLog WHERE LogID = 3
 
**********************************************************************************************/

BEGIN
SET NOCOUNT ON
-- Insert the record
INSERT INTO audit.StatisticLog(
LogID, ComponentName, Rows, TimeMS, MinRowsPerSec, MaxRowsPerSec
) VALUES (
ISNULL(@logID, 0), @ComponentName, @Rows, @TimeMS, @MinRowsPerSec, @MaxRowsPerSec
)
SET NOCOUNT OFF
END --procedure
GO






