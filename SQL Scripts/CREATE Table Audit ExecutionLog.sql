-- audit.ExecutionLog

PRINT N'Creating [audit].[ETL_ExecutionLog]'
GO
CREATE TABLE [audit].[ETL_ExecutionLog]
(
[LogID] [int] NOT NULL IDENTITY(1, 1),
[ParentLogID] [int] NULL,
[Description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PackageName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PackageGuid] [uniqueidentifier] NOT NULL,
[MachineName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ExecutionGuid] [uniqueidentifier] NOT NULL,
[LogicalDate] [datetime] NOT NULL,
[Operator] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StartTime] [datetime] NOT NULL,
[EndTime] [datetime] NULL,
[Status] [tinyint] NOT NULL,
[FailureTask] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
PRINT N'Creating primary key [PK_ExecutionLog] on [Audit].[ExecutionLog]'
GO
ALTER TABLE [Audit].[ETL_ExecutionLog] ADD CONSTRAINT [PK_ExecutionLog] PRIMARY KEY CLUSTERED ([LogID]) ON [PRIMARY]
GO