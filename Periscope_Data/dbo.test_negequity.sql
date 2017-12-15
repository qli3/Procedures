USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[test_negequity]    Script Date: 12/15/2017 4:41:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[test_negequity]
@Date datetime
AS
select *
from windhaven_report.dbo.policy pol
where 1=1
and pol.equityDate is not null
and left(pol.policyNum,1)<>'Q'
and pol.status=1
and convert(date,pol.equityDate)<@Date
GO

