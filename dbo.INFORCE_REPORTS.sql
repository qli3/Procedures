USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[INFORCE_REPORTS]    Script Date: 12/15/2017 4:40:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[INFORCE_REPORTS]
as
declare @reg_date date, @minDate date;

declare @i int;

declare @tempTable table(idx int identity(1,1), ratingVariable varchar(50),
	selectStatement varchar(max), joinStatement varchar(max), aggStatement varchar(max),
	primary key(idx));

declare @query varchar(max), @ratingVariable varchar(50), @selectStatement varchar(max), @joinStatement varchar(max),
	@aggStatement varchar(max);
/*
drop table Periscope_Data.dbo.inforceReport;
create table Periscope_Data.dbo.inforceReport
(STATE varchar(10), GROUPING VARCHAR(25), PROGRAM VARCHAR(10), GROUPED_BY VARCHAR(50),
REPORT_YEAR INTEGER, REPORT_MONTH INTEGER, COUNTORFACTOR DECIMAL(30,10),
PRIMARY KEY (STATE, GROUPING, PROGRAM, GROUPED_BY, REPORT_YEAR, REPORT_MONTH));
*/
insert into @tempTable(ratingVariable, selectStatement, joinStatement, aggStatement)
values
	('SEX-MARITAL',
		concat('concat(gender,',char(39),'-',char(39),',
			case maritalStatus when 10 then ',char(39),'S',char(39),'
				when 0 then ',char(39),'M',char(39),'
				else ',char(39),char(39),' end)'),
		concat('left join WIndhaven_Report.dbo.driver 
			on driver.policyId = policy.policyId and relationToApplicant = ',char(39),'INSURED',char(39),''),
		'count(distinct(policyNum))'),
			
	('HOME OWNER',
		concat('case when description is not null then ',char(39),'HOMEOWNER',char(39),'
				else ',char(39),'NON-HOMEOWNER',char(39),' end'),
		concat('left join WIndhaven_Report.dbo.PolicyDiscounts
		on policyDiscounts.policyId = policy.policyId and description = ',char(39),'Homeowner',char(39),''),
		'count(distinct(policyNum))'),
			
	('MULTICAR',
		concat('case when description is not null then ',char(39),'MULTICAR',char(39),'
				else ',char(39),'SINGLE CAR',char(39),' end'),
		concat('left join WIndhaven_Report.dbo.PolicyDiscounts
		on policyDiscounts.policyId = policy.policyId and description = ',char(39),'Multi-Car',char(39),''),
		'count(distinct(policyNum))'),
		
	('AGE',
		concat(char(39),'AVERAGE AGE',char(39)),
		concat('left join WIndhaven_Report.dbo.driver 
			on driver.policyId = policy.policyId and relationToApplicant = ',char(39),'INSURED',char(39),''),
		'avg(floor(datediff(day,convert(date,dob),convert(date,effectiveDate))/365.25))'),
			
	('NEW OR RENEWAL',
		concat('case when isRenewal = 0 then ',char(39),'NEW BUSINESS',char(39),'
				else ',char(39),'RENEWAL',char(39),' end'),
		'',
		'count(distinct(policyNum))');

set @i = 1;
while (@i <= (select count(*) from @tempTable))
begin
	set @ratingVariable = (select ratingVariable from @tempTable where idx = @i);
	set @selectStatement = (select selectStatement from @tempTable where idx = @i);
	set @joinStatement = (select joinStatement from @tempTable where idx = @i);
	set @aggStatement = (select aggStatement from @tempTable where idx = @i);

	set @reg_date = (select coalesce(eomonth(dateadd(month,1,max(datefromparts(REPORT_YEAR, REPORT_MONTH,1)))),'2016-12-31')
	from Periscope_Data.dbo.inforceReport
	where GROUPING = @ratingVariable);
	while @reg_date < convert(date,getdate())
	begin

		set @query = concat('
		insert into Periscope_Data.dbo.inforceReport
		select ProgState, ratingFactor, coalesce(ProgName,',char(39),'TOTAL',char(39),'),
		grouped, reg_year, reg_month, countorfactor
		from (
		select 
		ProgState,
		',char(39),@ratingVariable,char(39),' as ratingFactor,
		ProgName, 
		',@selectStatement,' as grouped,
		year(',char(39),@reg_date,char(39),') as reg_year,
		month(',char(39),@reg_date,char(39),') as reg_month,
		',@aggStatement,' as countorfactor
		from Windhaven_Report.dbo.policy
		join Periscope_Data.dbo.programNum on ratingProgram = ProgNum
		',@joinStatement,'
		where left(policyNum,1) <> ',char(39),'Q',char(39),'
			and convert(date,boundDate) <= ',char(39),@reg_date,char(39),'
			and  convert(date,effectiveDate) <= ',char(39),@reg_date,char(39),'
			and  convert(date,expirationDate) > ',char(39),@reg_date,char(39),'
			and  (convert(date,cancelledDate) > ',char(39),@reg_date,char(39),' or cancelledDate is null)
		group by ProgState, ProgName ',
			case when @ratingVariable in ('AGE') then ''
				else concat(', ',@selectStatement) end,' with cube) b
		where ProgState is not null and grouped is not null;');
		exec(@query);
		set @reg_date = eomonth(dateadd(month,1,@reg_date));
	end;
	set @i = @i + 1;
end;
GO

