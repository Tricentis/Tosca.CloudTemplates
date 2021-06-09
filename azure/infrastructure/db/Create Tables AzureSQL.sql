/****** Taken from %COMMANDER_HOME%\SQL ******/
/****** See https://support.tricentis.com/community/manuals_detail.do?lang=en&version=14.0.0&url=installation_tosca/prepare_multiuser.htm ******/
/****** Object:  Table [dbo].[tcIntAttr] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcIntAttr](
	[surrogate] [VARCHAR](36) NOT NULL,
	[attr] [int] NOT NULL,
	[value] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[surrogate] ASC,
	[attr] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [DIAATR] ******/
CREATE NONCLUSTERED INDEX [DIAATR] ON [dbo].[tcIntAttr] 
(
	[attr] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DIASUR] ******/
CREATE NONCLUSTERED INDEX [DIASUR] ON [dbo].[tcIntAttr] 
(
	[surrogate] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO
/****** Object:  Table [dbo].[tcStrAttr] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcStrAttr](
	[surrogate] [VARCHAR](36) NOT NULL,
	[attr] [int] NOT NULL,
	[value] [varchar](8000) NULL,
PRIMARY KEY CLUSTERED 
(
	[surrogate] ASC,
	[attr] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [DSAATR] ******/
CREATE NONCLUSTERED INDEX [DSAATR] ON [dbo].[tcStrAttr] 
(
	[attr] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DSASUR] ******/
CREATE NONCLUSTERED INDEX [DSASUR] ON [dbo].[tcStrAttr] 
(
	[surrogate] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO
/****** Object:  Table [dbo].[tcTextAttr] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcTextAttr](
	[surrogate] [VARCHAR](36) NOT NULL,
	[attr] [int] NOT NULL,
	[value] [text] NULL,
PRIMARY KEY CLUSTERED 
(
	[surrogate] ASC,
	[attr] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [DTAATR] ******/
CREATE NONCLUSTERED INDEX [DTAATR] ON [dbo].[tcTextAttr] 
(
	[attr] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DTASUR] ******/
CREATE NONCLUSTERED INDEX [DTASUR] ON [dbo].[tcTextAttr] 
(
	[surrogate] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO
/****** Object:  Table [dbo].[tcBinAttr] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcBinAttr](
	[surrogate] [VARCHAR](36) NOT NULL,
	[attr] [int] NOT NULL,
	[value] [varbinary](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[surrogate] ASC,
	[attr] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [DBAATR] ******/
CREATE NONCLUSTERED INDEX [DBAATR] ON [dbo].[tcBinAttr] 
(
	[attr] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DBASUR] ******/
CREATE NONCLUSTERED INDEX [DBASUR] ON [dbo].[tcBinAttr] 
(
	[surrogate] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO
/****** Object:  Table [dbo].[tcAggrValue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcAggrValue](
	[surrogate] [VARCHAR](36) NOT NULL,
	[assoc] [int] NOT NULL,
	[sequence] [int] NOT NULL,
	[partner] [VARCHAR](36) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[surrogate] ASC,
	[assoc] ASC,
	[partner] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [DGAASC] ******/
CREATE NONCLUSTERED INDEX [DGAASC] ON [dbo].[tcAggrValue] 
(
	[assoc] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DGAPSU] ******/
CREATE NONCLUSTERED INDEX [DGAPSU] ON [dbo].[tcAggrValue] 
(
	[partner] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DGASUR] ******/
CREATE NONCLUSTERED INDEX [DGASUR] ON [dbo].[tcAggrValue] 
(
	[surrogate] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO
/****** Object:  Table [dbo].[tcAssocValue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcAssocValue](
	[surrogate] [VARCHAR](36) NOT NULL,
	[assoc] [int] NOT NULL,
	[sequence] [int] NOT NULL,
	[partner] [VARCHAR](36) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[surrogate] ASC,
	[assoc] ASC,
	[partner] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [DAVASC] ******/
CREATE NONCLUSTERED INDEX [DAVASC] ON [dbo].[tcAssocValue] 
(
	[assoc] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DAVPSU] ******/
CREATE NONCLUSTERED INDEX [DAVPSU] ON [dbo].[tcAssocValue] 
(
	[partner] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DAVSUR] ******/
CREATE NONCLUSTERED INDEX [DAVSUR] ON [dbo].[tcAssocValue] 
(
	[surrogate] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO
/****** Object:  Table [dbo].[tcAggrValueC] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcAggrValueC](
	[surrogate] [VARCHAR](36) NOT NULL,
	[assoc] [int] NOT NULL,
	[sequence] [int] NOT NULL,
	[partner] [VARCHAR](36) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[surrogate] ASC,
	[assoc] ASC,
	[partner] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [DGCASC] ******/
CREATE NONCLUSTERED INDEX [DGCASC] ON [dbo].[tcAggrValueC] 
(
	[assoc] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DGCPSU] ******/
CREATE NONCLUSTERED INDEX [DGCPSU] ON [dbo].[tcAggrValueC] 
(
	[partner] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DGCSUR] ******/
CREATE NONCLUSTERED INDEX [DGCSUR] ON [dbo].[tcAggrValueC] 
(
	[surrogate] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO
/****** Object:  Table [dbo].[tcCluster] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcCluster](
	[surrogate] [VARCHAR](36) NOT NULL,
	[rev] [int] NOT NULL,
	[checkout_workspace] [varchar](600) NULL,
	[locked_by] [VARCHAR](36) NOT NULL,
	[syncpol] [int] NOT NULL DEFAULT ((2)),
	[branch_id] [VARCHAR](36) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[surrogate] ASC,
	[branch_id] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [DCCOWLCK] ******/
CREATE NONCLUSTERED INDEX [DCCOWLCK] ON [dbo].[tcCluster] 
(
	[checkout_workspace] ASC,
	[locked_by] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DCREV] ******/
CREATE NONCLUSTERED INDEX [DCREV] ON [dbo].[tcCluster] 
(
	[rev] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DCSYP] ******/
CREATE NONCLUSTERED INDEX [DCSYP] ON [dbo].[tcCluster] 
(
	[syncpol] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DCBRI] ******/
CREATE NONCLUSTERED INDEX [DCBRI] ON [dbo].[tcCluster] 
(
	[branch_id] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO
/****** Object:  Table [dbo].[tcObject] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcObject](
	[surrogate] [VARCHAR](36) NOT NULL,
	[typeId] [int] NOT NULL,
	[cluster] [VARCHAR](36) NOT NULL,
	[updaterev] [int] NOT NULL,
	[obj_data] [varbinary](max) NULL,
	[created_by] [VARCHAR](36) NOT NULL DEFAULT('0'),
	[created_at] [DATETIME] NULL,
	[modified_by] [VARCHAR](36) NOT NULL DEFAULT('0'),
	[modified_at] [DATETIME] NULL,
PRIMARY KEY CLUSTERED 
(
	[surrogate] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [DOCLU] ******/
CREATE NONCLUSTERED INDEX [DOCLU] ON [dbo].[tcObject] 
(
	[cluster] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DOTID] ******/
CREATE NONCLUSTERED INDEX [DOTID] ON [dbo].[tcObject] 
(
	[typeId] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DOUPR] ******/
CREATE NONCLUSTERED INDEX [DOUPR] ON [dbo].[tcObject] 
(
	[updaterev] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DOCLUUPR] ******/
CREATE NONCLUSTERED INDEX [DOCLUUPR] ON [dbo].[tcObject] 
(
	[cluster], [updaterev] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Table [dbo].[tcProperty] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcProperty](
	[name] [varchar](900) NOT NULL,
	[value] [varchar](8000) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[name] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)
GO
/****** Object:  Table [dbo].[tcMovedCluster] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcMovedCluster](
	[cluster1] [VARCHAR](36) NOT NULL,
	[cluster2] [VARCHAR](36) NOT NULL,

PRIMARY KEY CLUSTERED 
(
	[cluster1] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO
/****** Object:  Table [dbo].[tcRevision] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcRevision](
	[name] [varchar](900) NOT NULL,
	[value] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[name] ASC

) WITH (IGNORE_DUP_KEY = OFF)
)

GO
/****** Object:  Table [dbo].[tcRevLog] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcRevLog](
	[rev] [int] NOT NULL,
	[aquired] [datetime] NOT NULL,
	[approved] [datetime] NULL,
	[aquired_by] [varchar](8000) NULL,
	[tcuser] [VARCHAR](36) NULL,
	[comment] [varchar](8000) NULL,
PRIMARY KEY CLUSTERED 
(
	[rev] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [DRLAPT] ******/
CREATE NONCLUSTERED INDEX [DRLAPT] ON [dbo].[tcRevLog] 
(
	[approved] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DRLAQT] ******/
CREATE NONCLUSTERED INDEX [DRLAQT] ON [dbo].[tcRevLog] 
(
	[aquired] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DRLUSR] ******/
CREATE NONCLUSTERED INDEX [DRLUSR] ON [dbo].[tcRevLog] 
(
	[tcuser] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO
/****** Object:  Table [dbo].[tcSurrogate] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcSurrogate](
	[name] [varchar](900) NOT NULL,
	[value] [varchar](8000) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[name] ASC

) WITH (IGNORE_DUP_KEY = OFF)
)

GO
/****** Object:  Table [dbo].[tcNoSync] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcNoSync](
	[surrogate] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[surrogate] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO
/****** Object:  Table [dbo].[tcObjectHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcObjectHistory](
	[rev] [int] NOT NULL,
	[cluster] [VARCHAR](36) NOT NULL,
	[value] [varbinary](max) NOT NULL,
	[fw_cluster_value] [varbinary](max) NULL,
	[fw_object_value] [varbinary](max) NULL,
	[branch_id] [VARCHAR](36) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[rev] ASC,
	[cluster] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [DHOCLU] ******/
CREATE NONCLUSTERED INDEX [DHOCLU] ON [dbo].[tcObjectHistory] 
(
	[cluster] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DHOREV] ******/
CREATE NONCLUSTERED INDEX [DHOREV] ON [dbo].[tcObjectHistory] 
(
	[rev] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DHOBRI] ******/
CREATE NONCLUSTERED INDEX [DHOBRI] ON [dbo].[tcObjectHistory] 
(
	[branch_id] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Table [dbo].[tcDeletedObject] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcDeletedObject](
	[surrogate] [VARCHAR](36) NOT NULL,
	[cluster] [VARCHAR](36) NOT NULL,
	[updaterev] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[surrogate] ASC,
	[updaterev] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [DDOCLU] ******/
CREATE NONCLUSTERED INDEX [DDOCLU] ON [dbo].[tcDeletedObject] 
(
	[cluster] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DDOCLUUPR] ******/
CREATE NONCLUSTERED INDEX [DDOCLUUPR] ON [dbo].[tcDeletedObject] 
(
	[cluster] ASC,
	[updaterev] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DDOSUR] ******/
CREATE NONCLUSTERED INDEX [DDOSUR] ON [dbo].[tcDeletedObject] 
(
	[surrogate] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object:  Index [DDOUPR] ******/
CREATE NONCLUSTERED INDEX [DDOUPR] ON [dbo].[tcDeletedObject] 
(
	[updaterev] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO
/****** Object:  Table [dbo].[tcType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcType](
	[id] [int] NOT NULL,
	[name] [varchar](8000) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Table [dbo].[tcSequence] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tcSequence](
	[name] [varchar](10) NOT NULL,
	[value] [int] NOT NULL DEFAULT 0,
PRIMARY KEY CLUSTERED 
(
	[name] ASC

) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Table [dbo].[tcAttr] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcAttr](
	[id] [int] NOT NULL,
	[name] [varchar](8000) NOT NULL,
	[typeId] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [MIATID] ******/
CREATE NONCLUSTERED INDEX [MIATID] ON [dbo].[tcAttr] 
(
	[typeId] ASC
) WITH (IGNORE_DUP_KEY = OFF)
GO
/****** Object:  Table [dbo].[tcAssoc] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tcAssoc](
	[id] [int] NOT NULL,
	[name] [varchar](8000) NOT NULL,
	[typeId] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)

GO

/****** Object:  Index [MISTID] ******/
CREATE NONCLUSTERED INDEX [MISTID] ON [dbo].[tcAssoc] 
(
	[typeId] ASC
) WITH (IGNORE_DUP_KEY = OFF)

/****** Object: Table [dbo].[tcAccuIN] ******/
CREATE TABLE [dbo].[tcAccuIN]  (
	  [lowerrev] [int] NOT NULL , 
	  [upperrev] [int] NOT NULL , 
	  [aquired] [datetime] NOT NULL, 
	  [tcuser] [VARCHAR](36) NOT NULL, 
	  [comment] [varchar](8000)

PRIMARY KEY CLUSTERED 
(
	[upperrev] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)
GO

/****** Object:  Index [DCI] ******/
CREATE NONCLUSTERED INDEX [CILOWUPP] ON [dbo].[tcAccuIN] 
(
	[lowerrev] DESC,
	[upperrev] DESC
) WITH (IGNORE_DUP_KEY = OFF)
GO

/****** Object: Table [dbo].[tcAccuCH] ******/
CREATE TABLE [dbo].[tcAccuCH]  (
	  [cluster] [VARCHAR](36) NOT NULL ,
	  [lowerrev] [int] NOT NULL , 
	  [upperrev] [int] NOT NULL , 
	  [value] [varbinary](max) NOT NULL 

PRIMARY KEY CLUSTERED 
(
	[cluster] ASC,
	[upperrev] ASC
) WITH (IGNORE_DUP_KEY = OFF)
)
GO

/****** Object:  Table [dbo].[tcBranch] ******/
CREATE TABLE [dbo].[tcBranch](
	[id] [VARCHAR](36) NOT NULL,
	[originator] [VARCHAR](36) NOT NULL,
	[name] [VARCHAR](8000) NOT NULL,
	[rev] [INT] NOT NULL,
	[tcuser] [VARCHAR](36) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

INSERT INTO dbo.tcProperty VALUES ('BranchId', '9f82cab6-67d9-4a73-ad5c-c777cb2e2287')
GO

INSERT INTO dbo.tcProperty VALUES ('SchemaVersion', '12030000')
GO

INSERT INTO dbo.tcRevision VALUES ('Revision', 0)
GO

INSERT INTO dbo.tcSurrogate VALUES ('HighestSurrogate','0')
GO

INSERT [dbo].[tcBranch] ([id], [originator], [name], [rev], [tcuser]) VALUES ('9f82cab6-67d9-4a73-ad5c-c777cb2e2287', '9f82cab6-67d9-4a73-ad5c-c777cb2e2287', N'MASTER', 0, NULL)
GO

/* DECLARE @stmt VARCHAR(1000)
SET @stmt = 'ALTER DATABASE ' + db_name() + ' SET ALLOW_SNAPSHOT_ISOLATION ON';
EXEC(@stmt);

SET @stmt = 'ALTER DATABASE ' + db_name() + ' SET READ_COMMITTED_SNAPSHOT ON';
EXEC(@stmt); */
GO
