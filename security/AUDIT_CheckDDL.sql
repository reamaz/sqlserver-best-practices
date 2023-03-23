/* =====================================================================================
////////////////////////////    DESIGNED BY REAMAZ    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
////////////////////////////    === SQLDATA.RU ===    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
 ===================================================================================== */
 
-- Create Database for Audit results

USE master
GO
CREATE DATABASE Audit
GO

USE [Audit]
GO
/****** Object:  Table [dbo].[DDL_Audit]    Script Date: 07/23/2007 12:28:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[DDL_Audit](
	[DDL_Audit_ID] [int] IDENTITY(1,1) NOT NULL,
	[Event_Type] [varchar](100) NULL,
	[Database_Name] [varchar](100) NULL,
	[SchemaName] [varchar](100) NULL,
	[ObjectName] [varchar](100) NULL,
	[ObjectType] [varchar](100) NULL,
	[EventDate] [datetime] NULL,
	[SystemUser] [varchar](100) NULL,
	[CurrentUser] [varchar](100) NULL,
	[OriginalUser] [varchar](100) NULL,
	[EventDataText] [varchar](max) NULL
) ON [PRIMARY]

GO
GRANT INSERT ON DDL_Audit TO public
GO

-------------------------------------------------------------
-- Initial script to generate the auditing framework for all databases
-- Run in Text output mode
-- Remove any databases you do not want to audit.
-- Copy resulting text into a new SQL query and run to create audit triggers
-------------------------------------------------------------

sp_msforeachdb 'SELECT ''use ?
GO
SET ANSI_PADDING ON
GO
CREATE TRIGGER trg_DDL_Monitor_Change
ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
SET NOCOUNT ON
SET ANSI_PADDING ON
declare @EventType varchar(100)
declare @SchemaName varchar(100)
declare @DatabaseName varchar(100)
declare @ObjectName varchar(100)
declare @ObjectType varchar(100)
DECLARE @EventDataText VARCHAR(MAX)
SELECT 
 @EventType = EVENTDATA().value(''''(/EVENT_INSTANCE/EventType)[1]'''',''''nvarchar(max)'''')  
,@DatabaseName = EVENTDATA().value(''''(/EVENT_INSTANCE/DatabaseName)[1]'''',''''nvarchar(max)'''')  
,@SchemaName = EVENTDATA().value(''''(/EVENT_INSTANCE/SchemaName)[1]'''',''''nvarchar(max)'''')  
,@ObjectName = EVENTDATA().value(''''(/EVENT_INSTANCE/ObjectName)[1]'''',''''nvarchar(max)'''')
,@ObjectType = EVENTDATA().value(''''(/EVENT_INSTANCE/ObjectType)[1]'''',''''nvarchar(max)'''')   
,@EventDataText = EVENTDATA().value(''''(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]'''',''''nvarchar(max)'''')
insert into Audit.dbo.DDL_Audit (Event_Type, Database_Name, SchemaName, ObjectName, ObjectType
	, EventDate, SystemUser, CurrentUser, OriginalUser, EventDataText)
	select @EventType, @DatabaseName, @SchemaName, @ObjectName, @ObjectType
	, getdate(), SUSER_SNAME(), CURRENT_USER, ORIGINAL_LOGIN()
	, @EventDataText
GO
'''

-------------------------------------------------------------
-- Script used when e-mailing change results
-- Modify and use in a SQL Agent job w/ Database Mail to e-mail HTML results
-------------------------------------------------------------
IF EXISTS (SELECT 'x' FROM Audit.dbo.DDL_Audit
				WHERE Event_Type NOT LIKE '%statist%'
				AND SystemUser NOT IN (service account list here)
				AND EventDate >= convert(varchar(10),DATEADD(dd, -1, GETDATE()),101))

BEGIN
	DECLARE @email_from nvarchar(100)
		, @email_address nvarchar(200) 
		, @TheSubject nvarchar(255)

	SELECT @Email_Address = 'myemail@myemail.com' --change to desired recipients
	SET @email_from = 'DevServer@server.com' --change if needed for your server
	select @email_address as 'To:' ,  @email_from as 'From:'
	set @TheSubject = 'Recent Schema changes on ' + RTRIM(@@SERVERNAME)

	DECLARE @tableHTML  NVARCHAR(MAX) ;

--Modify query as needed to change results you see.
	SET @tableHTML =
		N'<H1>DevDB Schema Change</H1>' +
		N'<table border="1">' +
		N'<tr><th>Database_Name</th><th>SchemaName</th>' +
		N'<th>ObjectName</th><th>Event_Type</th><th>ObjectType</th>' +
		N'<th>EventDate</th><th>SystemUser</th><th>CurrentUser</th><th>OriginalUser</th><th>EventDataText</th></tr>' +
		CAST ( ( SELECT td = Database_Name,       '',
						td = SchemaName, '',
						td = ObjectName, '',
						td = Event_Type, '',
						td = ObjectType, '',
						td = EventDate, '',
						td = SystemUser, '',
						td = CurrentUser, '',
						td = OriginalUser, '',
						td = EventDataText
					FROM Audit.dbo.DDL_Audit
					WHERE Event_Type NOT LIKE '%statist%'
					AND SystemUser NOT IN (serviceaccount)
					AND EventDataText not like '%ALTER%INDEX%REBUILD%'
					AND EventDate >= convert(varchar(10),DATEADD(dd, -1, GETDATE()),101)
					ORDER BY Database_Name, ObjectType, ObjectName, EventDate, Event_Type
				  FOR XML PATH('tr'), TYPE 
		) AS NVARCHAR(MAX) ) +
		N'</table>' ;


	EXEC msdb.dbo.sp_send_dbmail
		@profile_name = 'Default' ,
		@recipients=@email_address,
		@subject = @TheSubject,
		@body = @tableHTML,
		@body_format = 'HTML' ;
END
