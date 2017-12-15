USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[dailySales]    Script Date: 12/15/2017 4:37:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[dailySales]
as

/*create table Periscope_Data.dbo.DAILY_SALES
(SALES_DATE date, PROGRAM varchar(7), SALES_COUNT bigint,
NB_PRMEIUM BIGINT, TOTAL_PREMIUM BIGINT, primary key (SALES_DATE, PROGRAM));*/

merge Periscope_Data.dbo.DAILY_SALES Target
using (select convert(date, applicationDate) as soldDate, progName, count(*) as polCount
from Windhaven_Report.dbo.policy
join [Periscope_Data].dbo.ProgramNum on ProgNum = ratingProgram
where isRenewal = 0 and left(policyNum,1) <> 'Q'
	and convert(date,applicationDate) > coalesce((select max(SALES_DATE) from Periscope_Data.dbo.DAILY_SALES where SALES_COUNT is not null),'2000-01-01')
	and convert(date,applicationDate) < convert(date,getdate())
group by convert(date,applicationDate),progName)  as Source
on (Source.soldDate = Target.SALES_DATE and Source.progName = Target.PROGRAM)
when matched then update set Target.SALES_COUNT = Source.polCount
when not matched by Target then
	insert (SALES_DATE, PROGRAM, SALES_COUNT)
	values (Source.soldDate, Source.progName, Source.polCount);

GO

