USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[HUDDLE_METRICS]    Script Date: 12/15/2017 4:39:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[HUDDLE_METRICS]
as
	declare @metrics table(idx int identity(1,1), metric_name varchar(50),
		page varchar(25), num varchar(100), denom varchar(100), pif int,
		color varchar(5), page_order int, format varchar(20),
		primary key (idx) );

	declare @i int, @j int;

	declare @metric varchar(max), @where_state varchar(max), @page varchar(max),
		@denom varchar(max), @pif_set_up int, @color varchar(max), @page_order varchar(max), @multiplier int,
		@format varchar(max), @query varchar(max), @date_grouping varchar(max), @date_where varchar(max), @date_column_name varchar(max);

	declare @date_used date,
		@yesterday date, @minYesterday date, @prior_week date, @prior_month date, @prior_year date,
		@yesterday2 date, @minYesterday2 date, @prior_week2 date, @prior_month2 date, @prior_year2 date, @dateAsOf date;

	/*
drop table Periscope_Data.dbo.HUDDLE_WEBPAGE;
	create table Periscope_Data.dbo.HUDDLE_WEBPAGE
(STATE varchar(20), PAGE_TYPE varchar(50), PAGE_ORDER INT, METRIC_NAME varchar(50), 
YESTERDAY decimal(20,5), PRIOR_WEEK decimal(20,5), PRIOR_MONTH decimal(20,5), PRIOR_YEAR decimal(20,5),
 PRIOR_YEAR2 decimal(20,5),
PIF_YESTERDAY INT, PIF_PRIOR_WEEK INT, PIF_PRIOR_MONTH INT, PIF_PRIOR_YEAR INT,
 PIF_PRIOR_YEAR2 INT,
YESTERDAY_DAYS INTEGER, PRIOR_WEEK_DAYS INTEGER, PRIOR_MONTH_DAYS INTEGER, PRIOR_YEAR_DAYS INTEGER,
PRIOR_YEAR2_DAYS INTEGER,
WEEKDAY_DISTRIBUTION varchar(max),
DAY_DISTRIBUTION varchar(max),
WEEK_DISTRIBUTION varchar(max),
MONTH_DISTRIBUTION varchar(max),
DISPLAY_FORMAT varchar(15), COLOR_SCALE VARCHAR(15), DATA_DATE DATE,
primary key (STATE, PAGE_TYPE, METRIC_NAME));
drop table Periscope_Data.dbo.HUDDLE_WEBPAGE_OLD;
	create table Periscope_Data.dbo.HUDDLE_WEBPAGE_OLD
(STATE varchar(20), PAGE_TYPE varchar(50), PAGE_ORDER INT, METRIC_NAME varchar(50), 
YESTERDAY decimal(20,5), PRIOR_WEEK decimal(20,5), PRIOR_MONTH decimal(20,5), PRIOR_YEAR decimal(20,5),
 PRIOR_YEAR2 decimal(20,5),
PIF_YESTERDAY INT, PIF_PRIOR_WEEK INT, PIF_PRIOR_MONTH INT, PIF_PRIOR_YEAR INT,
 PIF_PRIOR_YEAR2 INT,
YESTERDAY_DAYS INTEGER, PRIOR_WEEK_DAYS INTEGER, PRIOR_MONTH_DAYS INTEGER, PRIOR_YEAR_DAYS INTEGER,
PRIOR_YEAR2_DAYS INTEGER,
WEEKDAY_DISTRIBUTION varchar(max),
DAY_DISTRIBUTION varchar(max),
WEEK_DISTRIBUTION varchar(max),
MONTH_DISTRIBUTION varchar(max),
DISPLAY_FORMAT varchar(15), COLOR_SCALE VARCHAR(15), DATA_DATE DATE,
primary key (STATE, PAGE_TYPE, METRIC_NAME, DATA_DATE));
*/
delete from Periscope_Data.dbo.HUDDLE_WEBPAGE_OLD
where DATA_DATE = (select min(DATA_DATE) from Periscope_Data.dbo.HUDDLE_WEBPAGE);
insert into Periscope_Data.dbo.HUDDLE_WEBPAGE_OLD
select * from Periscope_Data.dbo.HUDDLE_WEBPAGE;

delete from Periscope_Data.dbo.HUDDLE_WEBPAGE;
set @date_used = convert(date,getdate());

	insert into @metrics(metric_name, page, page_order, num, denom, pif, color, format)
	values ('New Claims','Claims',0,
		concat(' like ',char(39),'Loss Count%',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('Claim Closures','Claims',1,
		concat(' = ',char(39),'Claim Closures',char(39),' '),
		'',
		1,
		'high',
		'int'),
	('Inventory','Claims',2,
		concat(' = ',char(39),'Inventory',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('Calls Received','Claims',3,
		concat(' = ',char(39),'Calls Received',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('Answer Rate','Claims',4,
		concat(' = ',char(39),'Calls Answered',char(39),' '),
		concat(' = ',char(39),'Calls Received',char(39),' '),
		0,
		'high',
		'percent0'),
	('Outbound Calls','Claims',5,
		concat(' = ',char(39),'Outbound Calls',char(39),' '),
		concat(' = ',char(39),'Calls Received',char(39),' '),
		0,
		'low',
		'ratio2'),
	('Recoveries','Claims',6,
		concat(' = ',char(39),'Recoveries',char(39),' '),
		'',
		1,
		'high',
		'dollar0'),
	('PIP Severity','Claims',7,
		' = null ',
		'',
		0,
		'low',
		'decimal'),
	('PD Severity','Claims',8,
		' = null ',
		'',
		0,
		'low',
		'decimal'),
	('BI Severity','Claims',9,
		' = null ',
		'',
		0,
		'low',
		'decimal'),
	('CMP Severity','Claims',10,
		' = null ',
		'',
		0,
		'low',
		'decimal'),
	('COL Severity','Claims',11,
		' = null ',
		'',
		0,
		'low',
		'decimal'),
	
	('PH Calls','Customer Service',0,
		concat(' = ',char(39),'PH Calls',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('PH ASA','Customer Service',1,
		concat(' = ',char(39),'PH ASA Time',char(39),' '),
		concat(' = ',char(39),'PH Calls',char(39),' '),
		0,
		'low',
		'secondsRatio'),
	('PH AHT','Customer Service',2,
		concat(' = ',char(39),'PH AHT Time',char(39),' '),
		concat(' = ',char(39),'PH Calls',char(39),' '),
		0,
		'low',
		'secondsRatio'),
	('PH ABD','Customer Service',3,
		concat(' = ',char(39),'PH Abandoned Calls',char(39),' '),
		concat(' = ',char(39),'PH Calls',char(39),' '),
		0,
		'low',
		'percent0'),
	('PH Chat','Customer Service',4,
		concat(' = ',char(39),'PH Chat',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('PH Surveys Submitted','Customer Service',5,
		concat(' = ',char(39),'PH Surveys Submitted',char(39),' '),
		'',
		1,
		'high',
		'int'),
	('PH Chat Satisfaction','Customer Service',6,
		concat(' = ',char(39),'PH Satisfied Chats',char(39),' '),
		concat(' = ',char(39),'PH Surveys Submitted',char(39),' '),
		0,
		'high',
		'percent0'),
	('Agent Calls','Customer Service',7,
		concat(' = ',char(39),'Agent Calls',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('Agent ASA','Customer Service',8,
		concat(' = ',char(39),'Agent ASA Time',char(39),' '),
		concat(' = ',char(39),'Agent Calls',char(39),' '),
		0,
		'low',
		'secondsRatio'),
	('Agent AHT','Customer Service',9,
		concat(' = ',char(39),'Agent AHT Time',char(39),' '),
		concat(' = ',char(39),'Agent Calls',char(39),' '),
		0,
		'low',
		'secondsRatio'),
	('Agent ABD','Customer Service',10,
		concat(' = ',char(39),'Agent Abandoned Calls',char(39),' '),
		concat(' = ',char(39),'Agent Calls',char(39),' '),
		0,
		'low',
		'percent0'),
	('Agent Chat','Customer Service',11,
		concat(' = ',char(39),'Agent Chat',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('Agent Surveys Submitted','Customer Service',12,
		concat(' = ',char(39),'Agent Surveys Submitted',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('Agent Chat Satisfaction (Did Chat Help)','Customer Service',13,
		concat(' = ',char(39),'Agent Helpful Chats',char(39),' '),
		concat(' = ',char(39),'Agent Surveys Submitted',char(39),' '),
		0,
		'high',
		'percent0'),
	('Agent Chat Satisfaction (was the rep friendly)','Customer Service',14,
		concat(' = ',char(39),'Agent Friendly Chats',char(39),' '),
		concat(' = ',char(39),'Agent Surveys Submitted',char(39),' '),
		0,
		'high',
		'percent0'),

	('NB outside standard','Shared Services',0,
		concat(' = ',char(39),'NB outside standard',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('ENDO outside standard','Shared Services',1,
		concat(' = ',char(39),'ENDO outside standard',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('FNOL Calls Received','Shared Services',2,
		concat(' = ',char(39),'FNOL Calls Received',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('FNOL Abandon','Shared Services',3,
		concat(' = ',char(39),'FNOL Abandoned Calls',char(39),' '),
		concat(' = ',char(39),'FNOL Calls Received',char(39),' '),
		0,
		'low',
		'percent0'),
	('FNOL ASA','Shared Services',4,
		concat(' = ',char(39),'FNOL ASA Time',char(39),' '),
		concat(' = ',char(39),'FNOL Calls Received',char(39),' '),
		0,
		'low',
		'secondsRatio'),
	('PHL Calls Received','Shared Services',5,
		concat(' = ',char(39),'PHL Calls Received',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('PHL Abandon','Shared Services',6,
		concat(' = ',char(39),'PHL Abandoned Calls',char(39),' '),
		concat(' = ',char(39),'PHL Calls Received',char(39),' '),
		0,
		'low',
		'percent0'),
	('PHL ASA','Shared Services',7,
		concat(' = ',char(39),'PHL ASA Time',char(39),' '),
		concat(' = ',char(39),'PHL Calls Received',char(39),' '),
		0,
		'low',
		'secondsRatio'),

	('New Suits','Legal',0,
		concat(' = ',char(39),'New Suits',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('Closed Suits','Legal',1,
		concat(' = ',char(39),'Closed Suits',char(39),' '),
		'',
		1,
		'high',
		'int'),
	('Win %','Legal',2,
		concat(' = ',char(39),'Won Suits',char(39),' '),
		concat(' = ',char(39),'Closed Suits',char(39),' '),
		0,
		'high',
		'percent0'),
	('Legal Inventory','Legal',3,
		concat(' = ',char(39),'Legal Inventory',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('MSJ Served','Legal',4,
		concat(' = ',char(39),'MSJ Served',char(39),' '),
		'',
		1,
		'high',
		'int'),
	('Depos Pending but Scheduled','Legal',5,
		concat(' = ',char(39),'Pending Scheduled Depos',char(39),' '),
		concat(' = ',char(39),'Legal Inventory',char(39),' '),
		0,
		'high',
		'percent0'),
	('Discovery in Process','Legal',6,
		concat(' = ',char(39),'Discovery in Process',char(39),' '),
		concat(' = ',char(39),'Legal Inventory',char(39),' '),
		0,
		'high',
		'percent0'),
	('Hearings','Legal',7,
		concat(' = ',char(39),'Hearings',char(39),' '),
		'',
		1,
		'high',
		'int'),

	('Requests','Product',0,
		concat(' = ',char(39),'Requests',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('Quotes','Product',1,
		concat(' = ',char(39),'Quotes',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('Hit Ratio','Product',2,
		concat(' = ',char(39),'Sales',char(39),' '),
		concat(' = ',char(39),'Quotes',char(39),' '),
		0,
		'high',
		'percent2'),
	('New Policies','Product',3,
		concat(' = ',char(39),'Sales',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('Average Premium New Business','Product',4,
		concat(' = ',char(39),'NB Premium',char(39),' '),
		concat(' = ',char(39),'Sales',char(39),' '),
		0,
		'high',
		'dollarRatio0'),
	('Carchex Sold','Product',5,
		concat(' = ',char(39),'Carchex',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('Policies Renewed','Product',6,
		concat(' = ',char(39),'Policies Renewed',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('Average Premium Renewal Business','Product',7,
		concat(' = ',char(39),'RN Premium',char(39),' '),
		concat(' = ',char(39),'Policies Renewed',char(39),' '),
		0,
		'high',
		'dollarRatio0'),
	('Retention Ratio','Product',8,
		concat(' = ',char(39),'Retained Policies',char(39),' '),
		concat(' = ',char(39),'Possible Retained Policies',char(39),' '),
		0,
		'high',
		'percent0'),
	('Policies Inforce','Product',9,
		concat(' = ',char(39),'PIF',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('Policies Inforce Change','Product',10,
		concat(' = ',char(39),'PIF Increase',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('Premium Inforce','Product',11,
		concat(' LIKE ',char(39),'EP -%',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('PIP Frequency','Product',12,
		concat(' = ',char(39),'Loss Count - PIP',char(39),' '),
		concat(' = ',char(39),'EXP - PIP',char(39),' '),
		0,
		'low',
		'ratio2'),
	('PD Frequency','Product',13,
		concat(' = ',char(39),'Loss Count - PD',char(39),' '),
		concat(' = ',char(39),'EXP - PD',char(39),' '),
		0,
		'low',
		'ratio2'),
	('BI Frequency','Product',14,
		concat(' = ',char(39),'Loss Count - BI',char(39),' '),
		concat(' = ',char(39),'EXP - BI',char(39),' '),
		0,
		'low',
		'ratio2'),
	('CMP Frequency','Product',15,
		concat(' = ',char(39),'Loss Count - CMP',char(39),' '),
		concat(' = ',char(39),'EXP - CMP',char(39),' '),
		0,
		'low',
		'ratio2'),
	('COL Frequency','Product',16,
		concat(' = ',char(39),'Loss Count - COL',char(39),' '),
		concat(' = ',char(39),'EXP - COL',char(39),' '),
		0,
		'low',
		'ratio2'),
	('UMBI Frequency','Product',17,
		concat(' = ',char(39),'Loss Count - UMBI',char(39),' '),
		concat(' = ',char(39),'EXP - UMBI',char(39),' '),
		0,
		'low',
		'ratio2'),
	('UMPD Frequency','Product',18,
		concat(' = ',char(39),'Loss Count - UMPD',char(39),' '),
		concat(' = ',char(39),'EXP - UMPD',char(39),' '),
		0,
		'low',
		'ratio2'),
	('PIP Losses per EP (000s)','Product',19,
		concat(' = ',char(39),'Loss Count - PIP',char(39),' '),
		concat(' = ',char(39),'EP - PIP',char(39),' '),
		0,
		'low',
		'ratio2'),
	('PD Losses per EP (000s)','Product',20,
		concat(' = ',char(39),'Loss Count - PD',char(39),' '),
		concat(' = ',char(39),'EP - PD',char(39),' '),
		0,
		'low',
		'ratio2'),
	('BI Losses per EP (000s)','Product',21,
		concat(' = ',char(39),'Loss Count - BI',char(39),' '),
		concat(' = ',char(39),'EP - BI',char(39),' '),
		0,
		'low',
		'ratio2'),
	('CMP Losses per EP (000s)','Product',22,
		concat(' = ',char(39),'Loss Count - CMP',char(39),' '),
		concat(' = ',char(39),'EP - CMP',char(39),' '),
		0,
		'low',
		'ratio2'),
	('COL Losses per EP (000s)','Product',23,
		concat(' = ',char(39),'Loss Count - COL',char(39),' '),
		concat(' = ',char(39),'EP - COL',char(39),' '),
		0,
		'low',
		'ratio2'),
	('APEX-STD Sales','Product',24,
		concat(' = ',char(39),'APEX-STD Sales',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('APEX-LTD Sales','Product',25,
		concat(' = ',char(39),'APEX-LTD Sales',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('EDGE-STD Sales','Product',26,
		concat(' = ',char(39),'EDGE-STD Sales',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('EDGE-LTD Sales','Product',27,
		concat(' = ',char(39),'EDGE-LTD Sales',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('PLUS-STD Sales','Product',28,
		concat(' = ',char(39),'PLUS-STD Sales',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('WIN Sales','Product',29,
		concat(' = ',char(39),'WIN Sales',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('SEL Sales','Product',30,
		concat(' = ',char(39),'SEL Sales',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('OPT Sales','Product',31,
		concat(' = ',char(39),'OPT Sales',char(39),' '),
		'',
		0,
		'high',
		'int'),
	('ICN Sales','Product',32,
		concat(' = ',char(39),'ICN Sales',char(39),' '),
		'',
		0,
		'high',
		'int'),

	('CC Payments','Policy Processing',0,
		concat(' = ',char(39),'CC Payments',char(39),' '),
		'',
		1,
		'high','int'),
	('Bank Payments','Policy Processing',1,
		concat(' = ',char(39),'Bank Payments',char(39),' '),
		'',
		1,
		'high',
		'int'),
	('NSFs Received','Policy Processing',2,
		concat(' = ',char(39),'NSFs Received',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('NSFs Processed','Policy Processing',3,
		concat(' = ',char(39),'NSFs Processed',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('NSFs Pending','Policy Processing',4,
		concat(' = ',char(39),'NSFs Pending',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('Cancellations for Non-Payment','Policy Processing',5,
		concat(' = ',char(39),'Cancellations for Non-Payment',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('Late Payments','Policy Processing',6,
		concat(' = ',char(39),'Late Payments',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('Reinstatements','Policy Processing',7,
		concat(' = ',char(39),'Reinstatements',char(39),' '),
		'',
		1,
		'high',
		'int'),
	('Fees in Dollars','Policy Processing',8,
		concat(' = ',char(39),'Fees',char(39),' '),
		'',
		1,
		'high',
		'dollar0'),
	('Refunds','Policy Processing',9,
		concat(' = ',char(39),'Refunds',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('Individual Pieces of Mail Sent','Policy Processing',10,
		concat(' = ',char(39),'Mail Sent',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('Emails sent by System','Policy Processing',11,
		concat(' = ',char(39),'System Emails',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('Policies with Negative Equity','Policy Processing',12,
		concat(' = ',char(39),'Policies with Negative Equity',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('Refunds Issued','Policy Processing',13,
		concat(' = ',char(39),'Refunds Issued',char(39),' '),
		'',
		1,
		'low',
		'int'),

	('New Complaints with TDI','Customer Opinion',0,
		concat(' = ',char(39),'TDI Complaints',char(39),' '),
		'',
		1,
		'low',
		'int'),
	('New Internet Complaints with 1 or 2 Stars','Customer Opinion',1,
		concat(' = ',char(39),'Internet Complaints',char(39),' '),
		'',
		1,
		'low',
		'int'),

	('Minutes of Latency on Core System','Windhaven IT',0,
		concat(' = ',char(39),'Core System Latency',char(39),' '),
		'',
		0,
		'low',
		'int'),
	('Complaints to IT Help Desk about Core System','Windhaven IT',1,
		concat(' = ',char(39),'Core System Complaints',char(39),' '),
		'',
		0,
		'low',
		'int'),
	('Complaints to IT Help Desk about Phones','Windhaven IT',2,
		concat(' = ',char(39),'Phone Complaints',char(39),' '),
		'',
		0,
		'low',
		'int');

	set @i = 1;
	while (@i <= (select count(*) from @metrics))
	begin
		set @metric = (select metric_name from @metrics where idx = @i);
		set @page = (select page from @metrics where idx = @i);
		set @page_order = (select page_order from @metrics where idx = @i);
		set @where_state = (select num from @metrics where idx = @i);
		set @denom = (select denom from @metrics where idx = @i);
		set @pif_set_up = (select pif from @metrics where idx = @i);
		set @color = (select color from @metrics where idx = @i);
		set @format = (select format from @metrics where idx = @i);
		set @multiplier = case when @metric like '%Losses per EP%' then 1000
			when @metric = 'Premium Inforce' then 365
			else 1 end;

		set @yesterday = dateadd(day,-1,@date_used);
		set @minYesterday = dateadd(day,
			case when @metric in ('Policies with Negative Equity','Inventory','Legal Inventory',
			'Employees','Positions Open','Pending Hires','Policies Inforce','Premium Inforce','NSFs Pending') then -1
				when datename(dw,@date_used) = 'Monday' then -3
				when datename(dw,@date_used) = 'Sunday' then -2
				else -1 end,@date_used);
		set @prior_week = dateadd(week,-1,@date_used);
		set @prior_month = dateadd(day,-28,@date_used);
		set @prior_year = dateadd(day,-365,@date_used);
		
		set @minYesterday2 = dateadd(week,-1,dateadd(day,
			case when @metric in ('Policies with Negative Equity','Inventory','Legal Inventory',
			'Employees','Positions Open','Pending Hires','Policies Inforce','Premium Inforce','NSFs Pending') then -1
				when datename(dw,@date_used) = 'Monday' then -3
				when datename(dw,@date_used) = 'Sunday' then -2
				else -1 end,@date_used));
		set @prior_week2 = dateadd(week,-2,@date_used);
		set @prior_month2 = dateadd(day,-56,@date_used);
		set @prior_year2 = dateadd(day,-730,@date_used);


		set @query = concat('
		insert into Periscope_Data.dbo.HUDDLE_WEBPAGE
		select progState, ',char(39),@page,char(39),', 
				',char(39),@page_order,char(39),', 
				',char(39),@metric,char(39),',
			sum(case when DATA_DATE between ',char(39),@minYesterday,char(39),' and ',char(39),@yesterday,char(39),'
				and HUDDLE_METRIC ',@where_state,' then METRIC_NUMBER*',@multiplier,' end)',
				case when @denom = '' then '' else
				concat('/nullif(sum(case when DATA_DATE between ',char(39),@minYesterday,char(39),' and ',char(39),@yesterday,char(39),'
					and HUDDLE_METRIC ',@denom,' then METRIC_NUMBER end),0)') end,' as yesterday,

			sum(case when DATA_DATE between ',char(39),@prior_week,char(39),' and ',char(39),@yesterday,char(39),'
				and HUDDLE_METRIC ',@where_state,' then METRIC_NUMBER*',@multiplier,' end)',
				case when @denom = '' then '' else
				concat('/nullif(sum(case when DATA_DATE between ',char(39),@prior_week,char(39),' and ',char(39),@yesterday,char(39),'
					and HUDDLE_METRIC ',@denom,' then METRIC_NUMBER end),0)') end,' as prior_week,

			sum(case when DATA_DATE between ',char(39),@prior_month,char(39),' and ',char(39),@yesterday,char(39),'
				and HUDDLE_METRIC ',@where_state,' then METRIC_NUMBER*',@multiplier,' end)',
				case when @denom = '' then '' else
				concat('/nullif(sum(case when DATA_DATE between ',char(39),@prior_month,char(39),' and ',char(39),@yesterday,char(39),'
					and HUDDLE_METRIC ',@denom,' then METRIC_NUMBER end),0)') end,' as prior_month,

			sum(case when DATA_DATE between ',char(39),@prior_year,char(39),' and ',char(39),@yesterday,char(39),'
				and HUDDLE_METRIC ',@where_state,' then METRIC_NUMBER*',@multiplier,' end)',
				case when @denom = '' then '' else
				concat('/nullif(sum(case when DATA_DATE between ',char(39),@prior_year,char(39),' and ',char(39),@yesterday,char(39),'
					and HUDDLE_METRIC ',@denom,' then METRIC_NUMBER end),0)') end,' as prior_year,

			sum(case when DATA_DATE between ',char(39),@prior_year2,char(39),' and ',char(39),dateadd(day,-1,@prior_year),char(39),'
				and HUDDLE_METRIC ',@where_state,' then METRIC_NUMBER*',@multiplier,' end)',
				case when @denom = '' then '' else
				concat('/nullif(sum(case when DATA_DATE between ',char(39),@prior_year2,char(39),' and ',char(39),dateadd(day,-1,@prior_year),char(39),'
					and HUDDLE_METRIC',@denom,' then METRIC_NUMBER end),0)') end,' as prior_year2,

		',case when @pif_set_up = 0 then
		'	1 as pif_yesterday,
			1 as pif_prior_week,
			1 as pif_prior_month,
			1 as pif_prior_year,
			1 as pif_prior_year2,
		'
		else
			concat(concat(' sum(case when DATA_DATE between ',char(39),@minYesterday,char(39),' and 
				',char(39),@yesterday,char(39),' and HUDDLE_METRIC = ',char(39),'PIF',char(39),' and
			(datename(dw,DATA_DATE) not in (',char(39),'Saturday',char(39),',',char(39),'Sunday',char(39),')
				or ',char(39),@metric,char(39),' in (',char(39),'Inventory',char(39),',',char(39),'Employees',char(39),',
				',char(39),'Positions Open',char(39),',',char(39),'Pending Hires',char(39),',
				',char(39),'Clutch Employees',char(39),',',char(39),'Legal Inventory',char(39),',
				',char(39),'Policies with Negative Equity',char(39),',
				',char(39),'Policies Inforce',char(39),',
				',char(39),'NSFs Pending',char(39),',
				',char(39),'Premium Inforce',char(39),') )
				then METRIC_NUMBER end) as pif_yesterday, '),
			concat('	
			sum(case when DATA_DATE between ',char(39),@prior_week,char(39),' and 
				',char(39),@yesterday,char(39),' and HUDDLE_METRIC = ',char(39),'PIF',char(39),' and
			(datename(dw,DATA_DATE) not in (',char(39),'Saturday',char(39),',',char(39),'Sunday',char(39),')
				or ',char(39),@metric,char(39),' in (',char(39),'Inventory',char(39),',',char(39),'Employees',char(39),',
				',char(39),'Positions Open',char(39),',',char(39),'Pending Hires',char(39),',
				',char(39),'Clutch Employees',char(39),',',char(39),'Legal Inventory',char(39),',
				',char(39),'Policies with Negative Equity',char(39),',
				',char(39),'Policies Inforce',char(39),',
				',char(39),'NSFs Pending',char(39),',
				',char(39),'Premium Inforce',char(39),') )
				then METRIC_NUMBER end) as pif_prior_week,'),
			concat('	
			sum(case when DATA_DATE between ',char(39),@prior_month,char(39),' and 
				',char(39),@yesterday,char(39),' and HUDDLE_METRIC = ',char(39),'PIF',char(39),' and
			(datename(dw,DATA_DATE) not in (',char(39),'Saturday',char(39),',',char(39),'Sunday',char(39),')
				or ',char(39),@metric,char(39),' in (',char(39),'Inventory',char(39),',',char(39),'Employees',char(39),',
				',char(39),'Positions Open',char(39),',',char(39),'Pending Hires',char(39),',
				',char(39),'Clutch Employees',char(39),',',char(39),'Legal Inventory',char(39),',
				',char(39),'Policies with Negative Equity',char(39),',
				',char(39),'Policies Inforce',char(39),',
				',char(39),'NSFs Pending',char(39),',
				',char(39),'Premium Inforce',char(39),') )
				then METRIC_NUMBER end) as pif_prior_month,'),
			concat('	
			sum(case when DATA_DATE between ',char(39),@prior_year,char(39),' and 
				',char(39),@yesterday,char(39),' and HUDDLE_METRIC = ',char(39),'PIF',char(39),' and
			(datename(dw,DATA_DATE) not in (',char(39),'Saturday',char(39),',',char(39),'Sunday',char(39),')
				or ',char(39),@metric,char(39),' in (',char(39),'Inventory',char(39),',',char(39),'Employees',char(39),',
				',char(39),'Positions Open',char(39),',',char(39),'Pending Hires',char(39),',
				',char(39),'Clutch Employees',char(39),',',char(39),'Legal Inventory',char(39),',
				',char(39),'Policies with Negative Equity',char(39),',
				',char(39),'Policies Inforce',char(39),',
				',char(39),'NSFs Pending',char(39),',
				',char(39),'Premium Inforce',char(39),') )
				then METRIC_NUMBER end) as pif_prior_year,'),
			concat('	
			sum(case when DATA_DATE between ',char(39),@prior_year2,char(39),' and 
				',char(39),dateadd(day,-1,@prior_year),char(39),' and HUDDLE_METRIC = ',char(39),'PIF',char(39),' and
			(datename(dw,DATA_DATE) not in (',char(39),'Saturday',char(39),',',char(39),'Sunday',char(39),')
				or ',char(39),@metric,char(39),' in (',char(39),'Inventory',char(39),',',char(39),'Employees',char(39),',
				',char(39),'Positions Open',char(39),',',char(39),'Pending Hires',char(39),',
				',char(39),'Clutch Employees',char(39),',',char(39),'Legal Inventory',char(39),',
				',char(39),'Policies with Negative Equity',char(39),',
				',char(39),'Policies Inforce',char(39),',
				',char(39),'NSFs Pending',char(39),',
				',char(39),'Premium Inforce',char(39),') )
				then METRIC_NUMBER end) as pif_prior_year2,')
			)
		end,
		'',
		concat(
		concat('count(distinct(case when DATA_DATE between ',char(39),@minYesterday,char(39),' and ',char(39),@yesterday,char(39),'
		and HUDDLE_METRIC ',@where_state,' and 
		(datename(dw,DATA_DATE) not in (',char(39),'Saturday',char(39),',',char(39),'Sunday',char(39),') or 
			',char(39),@metric,char(39),' in 
			(',char(39),'Inventory',char(39),',',char(39),'Employees',char(39),',',char(39),'Positions Open',char(39),',
			',char(39),'Pending Hires',char(39),',',char(39),'Clutch Employees',char(39),',',char(39),'Legal Inventory',char(39),',
			',char(39),'Policies with Negative Equity',char(39),',
				',char(39),'Policies Inforce',char(39),',
				',char(39),'NSFs Pending',char(39),',
				',char(39),'Premium Inforce',char(39),') )
		then DATA_DATE end)) as yesterday_days,'),
		concat('
		count(distinct(case when DATA_DATE between ',char(39),@prior_week,char(39),' and ',char(39),@yesterday,char(39),'
		and HUDDLE_METRIC ',@where_state,' and 
		(datename(dw,DATA_DATE) not in (',char(39),'Saturday',char(39),',',char(39),'Sunday',char(39),') or 
			',char(39),@metric,char(39),' in 
			(',char(39),'Inventory',char(39),',',char(39),'Employees',char(39),',',char(39),'Positions Open',char(39),',
			',char(39),'Pending Hires',char(39),',',char(39),'Clutch Employees',char(39),',',char(39),'Legal Inventory',char(39),',
			',char(39),'Policies with Negative Equity',char(39),',
				',char(39),'Policies Inforce',char(39),',
				',char(39),'NSFs Pending',char(39),',
				',char(39),'Premium Inforce',char(39),') )
		then DATA_DATE end)) as prior_week_days,'),
		concat('
		count(distinct(case when DATA_DATE between ',char(39),@prior_month,char(39),' and ',char(39),@yesterday,char(39),'
		and HUDDLE_METRIC ',@where_state,' and 
		(datename(dw,DATA_DATE) not in (',char(39),'Saturday',char(39),',',char(39),'Sunday',char(39),') or 
			',char(39),@metric,char(39),' in 
			(',char(39),'Inventory',char(39),',',char(39),'Employees',char(39),',',char(39),'Positions Open',char(39),',
			',char(39),'Pending Hires',char(39),',',char(39),'Clutch Employees',char(39),',',char(39),'Legal Inventory',char(39),',
			',char(39),'Policies with Negative Equity',char(39),',
				',char(39),'Policies Inforce',char(39),',
				',char(39),'NSFs Pending',char(39),',
				',char(39),'Premium Inforce',char(39),') )
		then DATA_DATE end)) as prior_month_days,'),
		concat('
		count(distinct(case when DATA_DATE between ',char(39),@prior_year,char(39),' and ',char(39),@yesterday,char(39),'
		and HUDDLE_METRIC ',@where_state,' and 
		(datename(dw,DATA_DATE) not in (',char(39),'Saturday',char(39),',',char(39),'Sunday',char(39),') or 
			',char(39),@metric,char(39),' in 
			(',char(39),'Inventory',char(39),',',char(39),'Employees',char(39),',',char(39),'Positions Open',char(39),',
			',char(39),'Pending Hires',char(39),',',char(39),'Clutch Employees',char(39),',',char(39),'Legal Inventory',char(39),',
			',char(39),'Policies with Negative Equity',char(39),',
				',char(39),'Policies Inforce',char(39),',
				',char(39),'NSFs Pending',char(39),',
				',char(39),'Premium Inforce',char(39),') )
		then DATA_DATE end)) as prior_year_days,'),
		concat('
		count(distinct(case when DATA_DATE between ',char(39),@prior_year2,char(39),' and ',char(39),dateadd(day,-1,@prior_year),char(39),'
		and HUDDLE_METRIC ',@where_state,' and 
		(datename(dw,DATA_DATE) not in (',char(39),'Saturday',char(39),',',char(39),'Sunday',char(39),') or 
			',char(39),@metric,char(39),' in 
			(',char(39),'Inventory',char(39),',',char(39),'Employees',char(39),',',char(39),'Positions Open',char(39),',
			',char(39),'Pending Hires',char(39),',',char(39),'Clutch Employees',char(39),',',char(39),'Legal Inventory',char(39),',
			',char(39),'Policies with Negative Equity',char(39),',
				',char(39),'Policies Inforce',char(39),',
				',char(39),'NSFs Pending',char(39),',
				',char(39),'Premium Inforce',char(39),') )
		then DATA_DATE end)) as prior_year2_days')

		),'null,null,null,null,null
		, ',char(39),@format,char(39),', ',char(39),@color,char(39),', null

		from Periscope_Data.dbo.HUDDLE_DATA
		join (select distinct DATA_DATE as checkDate from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC ',@where_state,') b on checkDate = DATA_DATE ',
		case when @denom = '' then '' else 
		concat('join (select distinct DATA_DATE as denomCheckDate from Periscope_data.dbo.HUDDLE_DATA where HUDDLE_METRIC ',@denom,') c 
			on denomCheckDate = DATA_DATE') end,'
			right join (select distinct STATE as progState from Periscope_Data.dbo.HUDDLE_DATA) e on STATE = progState
		group by progState
		');
		exec(@query);


			set @j = 0;
			while @j < 4
			begin
				set @date_grouping = case when @j IN (0,1) then
					concat('dateadd(day, -case when datename(dw,DATA_DATE) = ',char(39),'Sunday',char(39),
						' then 2 when datename(dw,DATA_DATE) = ',char(39),'Saturday',char(39),' then 1 else 0 end,DATA_DATE)')
					when @j = 2 then 'dateadd(day,-(datepart(dw,DATA_DATE)+5)%7,DATA_DATE)'
					when @j = 3 then 'dateadd(day,-(datepart(dayofyear,DATA_DATE)%28),DATA_DATE)'
					end;
				set @date_where = case when @j in(0,2,3) then ''
					when @j = 1 then CONCAT(' AND datepart(dw,',@date_grouping,') = DATEpart(dw,DATEADD(DAY,
						-CASE WHEN DATENAME(dw,',char(39),@date_used,char(39),') = ',CHAR(39),'Monday',char(39),' then 3 when datename(dw,',char(39),@date_used,char(39),') = ',char(39),'Sunday',char(39),' then 2 else 1 end,
						',char(39),@date_used,char(39),'))')
					when @j = 2 then concat(' and ',@date_grouping,' < convert(date,dateadd(day,-datepart(dw,',char(39),@date_used,char(39),')+5%7,',char(39),@date_used,char(39),')')
					when @j = 3 then concat(' and ',@date_grouping,' < convert(date,dateadd(day,-datepart(dayofyear,',char(39),@date_used,char(39),')%28,',char(39),@date_used,char(39),') and 
					datepart(dayofyear,DATA_DATE) <= 364 ')
				end;
				set @date_column_name = case when @j = 0 then 'DAY_DISTRIBUTION'
				when @j = 1 then 'WEEKDAY_DISTRIBUTION'
				when @j = 2 then 'WEEK_DISTRIBUTION'
				when @j = 3 then 'MONTH_DISTRIBUTION'
				end;
				set @query = concat('

					merge Periscope_Data.dbo.HUDDLE_WEBPAGE as Target
					using (select STATE, ',char(39),@page,char(39),' as PAGE, 
					',char(39),@metric,char(39),' as METRIC, 
					stuff((select ',char(39),',',char(39),' + ',char(39),'{',char(39),' +char(34)+',char(39),'d',char(39),'+char(34)+',char(39),':',char(39),'+char(34)+convert(varchar(10),DATA_DATE)+char(34)+',char(39),',',char(39),'+char(34)+',
						char(39),'n',char(39),' + char(34) + ',char(39),':',char(39),' + rtrim(cast(RESULTING_METRIC as char)) + ',char(39),'}',char(39),'
					from (
					select STATE, ',@date_grouping,' as DATA_DATE, 
						((sum(case when HUDDLE_METRIC ',@where_state,' then METRIC_NUMBER*',@multiplier,' end)',
						case when @denom = '' then '' else
						concat('/nullif(sum(case when HUDDLE_METRIC ',@denom,' then METRIC_NUMBER end),0)') end,')
					',case when @pif_set_up = 0 then '' ELSE
						concat('/nullif(sum(case when HUDDLE_METRIC = ',char(39),'PIF',char(39),'  and 
					(datename(dw,DATA_DATE) not in (',char(39),'Sunday',char(39),',',char(39),'Saturday',char(39),') or 
						',char(39),@metric,char(39),' in 
							(',char(39),'Inventory',char(39),',
							',char(39),'Employees',char(39),',
							',char(39),'Positions Open',char(39),',
							',char(39),'Pending Hires',char(39),',
							',char(39),'Clutch Employees',char(39),',
							',char(39),'Legal Inventory',char(39),',
							',char(39),'NSFs Pending',char(39),',
							',char(39),'Policies with Negative Equity',char(39),',
					',char(39),'Policies Inforce',char(39),',
					',char(39),'Premium Inforce',char(39),') )
					then METRIC_NUMBER end),0)') end,')',case when @pif_set_up = 0 and @format in ('int','seconds','dollar0') then
					concat('/nullif(count(distinct(case when HUDDLE_METRIC ',@where_state,' and
					(datepart(dw,DATA_DATE) not in (7,1) or 
						',char(39),@metric,char(39),' in (',char(39),'Inventory',char(39),',',char(39),'Employees',char(39),',',
						char(39),'Positions Open',char(39),',',char(39),'Pending Hires',char(39),',',
						char(39),'Clutch Employees',char(39),',',char(39),'Legal Inventory',char(39),',',
						char(39),'NSFs Pending',char(39),',',
						char(39),'Policies with Negative Equity',char(39),',',char(39),'Policies Inforce',char(39),',',char(39),'Premium Inforce',char(39),') )
						then DATA_DATE end)),0)') else '' end,' as RESULTING_METRIC
					from Periscope_Data.dbo.HUDDLE_DATA d
					join (select distinct DATA_DATE as checkDate from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC ',@where_state,') b on checkDate = DATA_DATE ',
		case when @denom = '' then '' else 
		concat('join (select distinct DATA_DATE as denomCheckDate from Periscope_data.dbo.HUDDLE_DATA where HUDDLE_METRIC ',@denom,') c 
			on denomCheckDate = DATA_DATE') end,'
					where DATA_DATE between ',char(39),case when @j = 3 then @prior_year2 else @prior_year end,char(39),' and ',char(39),@yesterday,char(39),'
					',@date_where,' and a.STATE = d.STATE
					 group by ',@date_grouping,', STATE) b
					 order by DATA_DATE desc
					 for XML PATH(',char(39),char(39),')
					 ),1,1,',char(39),char(39),'
					 ) as DISTRIBUTION    
					 from (select distinct STATE from  Periscope_Data.dbo.HUDDLE_DATA  ) a
					) as Source
					on PAGE_TYPE = PAGE and METRIC_NAME = METRIC and Target.STATE = Source.STATE
					when matched then update set 
						',@date_column_name,' = DISTRIBUTION
					when not matched by Target then
					insert (PAGE_TYPE, METRIC_NAME, ',@date_column_name,', STATE)
					values (PAGE, METRIC, DISTRIBUTION, Source.STATE);

					');
			exec(@query);
			set @j = @j + 1;
		end;
		set @i = @i + 1;
	end;


	set @i = 0;
	while @i <= 4
	begin

			SET @dateAsOf = CASE WHEN @i = 0 THEN @minYesterday
				WHEN @i IN (1,2,3) THEN @yesterday
				WHEN @i = 4 THEN dateadd(day,-1,@prior_year) END;
			merge Periscope_Data.dbo.HUDDLE_WEBPAGE as Target
			using (select STATE, 'Claims' as pageType,
				case coverage when 'PIP' then 7 when 'PD' then 8 when 'BI' then 9 when 'CMP' then 10 when 'COL' then 11 end as pageOrder, 
				concat(coverage,' Severity') as metricName, 
				case when @i = 0 then sum(coalesce(paidAmount,0)/coalesce(lossCount,0)) end as Yesterday, 
				case when @i = 1 then sum(coalesce(paidAmount,0)/coalesce(lossCount,0)) end as priorWeek, 
				case when @i = 2 then sum(coalesce(paidAmount,0)/coalesce(lossCount,0)) end as priorMonth, 
				case when @i = 3 then sum(coalesce(paidAmount,0)/coalesce(lossCount,0)) end as priorYear, 
				case when @i = 4 then sum(coalesce(paidAmount,0)/coalesce(lossCount,0)) end as priorYear2,
				1 as pifYesterday, 1 as pifPriorWeek, 1 as pifPriorMonth, 1 as pifPriorYear, 1 as pifPriorYear2,
				1 as yesterdayDays, 1 as priorWeekDays, 1 as priorMonthDays, 1 as priorYearDays, 1 as priorYear2Days,
				'dollarRatio0' as displayFormat, 'low' as colorScale
				from (
				select progState as STATE, dateLabel as minDate, coverage,
				sum(paidAmount) as paidAmount, count(*) as lossCount
				from (
				select ClaimNumber, Coverage, min(dateOpened) as minDate, progSTate,
				case when @i = 0 then convert(char(10),convert(date,min(dateOpened)))
					when @i = 1 then concat(datepart(yy,min(dateOpened)),'-',datepart(wk,min(dateOpened)))
					when @i = 2 then concat(datepart(yy,min(dateOpened)),'-',datepart(mm,min(dateOpened)))
					when @i in (3,4) then convert(char(4),datepart(yy,min(dateOpened))) end as dateLabel,
				sum(case when convert(date,TranDate) between case @i when 0 then @minYesterday when 1 then @prior_week when 2 then @prior_month when 3 then @prior_year when 4 then @prior_year2 end and @dateAsOf then paidAmount end) as paidAmount

				from (
				select ClaimNumber, Coverage, TranDate, dateOpened, Loss_Date, source, rowNum, progState,
				lossPaid - coalesce(lag(lossPaid) over(partition by ClaimNumber, Coverage order by TranDate, rowNum),0) as paidAmount,
				lossPaid
				from (
				select a.*,
				row_number() over(order by ClaimNumber, Coverage, TranDate) as rowNum

				from (
				select ClaimNumber, Coverage, TranDate,TranDate as dateOpened, Loss_Date,'TX' as progState,
				 sum(Amount) over(partition by ClaimNumber, Coverage order by TranDate asc, rowNum asc ) as lossPaid, 'B2' as source
				from (
				select ClaimNumber, Coverage, TranDate, Loss_Date, case when TranType = 'Payment' then Amount else 0 end as Amount,
				row_number() over(order by ClaimNumber, Coverage, TranDate) as rowNum
				from Periscope_Data.B2_Data.Claims_Trans) b
				union all
				select 
				a.claimNum,
				case a.policyCoveragesId when 20 then 'COL' when 19 then 'CMP' when 11 then 'BI' when 12 then 'PD' when 22 then 'PIP'
					when 15 then 'UMPD' when 14 then 'UMBI' when 27 then 'RENT' when 24 then 'TOW' when 18 then 'UNPD'when 36 then 'UNBI' when 51 then 'CDW'
				end,
				a.dateChanged, a.dateOpened, dateOfLoss, progState,
				a.lossPaid+a.salvagePaid+a.subrogationPaid, 'SV'
				from Windhaven_Report.dbo.ClaimLog a
				join Windhaven_Report.dbo.claim on a.claimID = claim.claimID
				join Windhaven_Report.dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
				join [Windhaven_Report].dbo.policy on policy.policyId = claimincident.policyId
				join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
				where a.claimNum <> '0') a) a) a
				group by ClaimNumber, Coverage, progState
				having min(dateOpened) between dateadd(month,-72,@dateAsOf) and @dateAsOf) a
				where datepart(dw,minDate) not in (1,7) or @i not in (0)
				group by dateLabel, Coverage, progState) a
				where coverage in ('PIP','PD','COL','CMP','BI')
				group by coverage, STATE) as Source
			on Target.PAGE_TYPE = Source.PageType and Target.METRIC_NAME = Source.MetricName and Target.STATE = Source.STATE
			when matched then
				update set Target.YESTERDAY = case when @i = 0 then Source.Yesterday else Target.YESTERDAY end,
					Target.PRIOR_WEEK = case when @i = 1 then Source.priorWeek else Target.PRIOR_WEEK end,
					Target.PRIOR_MONTH = case when @i = 2 then Source.priorMonth else Target.PRIOR_MONTH end,
					Target.PRIOR_YEAR = case when @i = 3 then Source.priorYear else Target.PRIOR_YEAR end,
					Target.PRIOR_YEAR2 = case when @i = 4 then Source.priorYear2 else Target.PRIOR_YEAR2 end,
					Target.PAGE_ORDER = Source.pageOrder

			when not matched by Target then
			insert (STATE, PAGE_TYPE, PAGE_ORDER, METRIC_NAME, YESTERDAY, PRIOR_WEEK, PRIOR_MONTH, PRIOR_YEAR, PRIOR_YEAR2,
					PIF_YESTERDAY, PIF_PRIOR_WEEK, PIF_PRIOR_MONTH, PIF_PRIOR_YEAR, PIF_PRIOR_YEAR2,
					YESTERDAY_DAYS, PRIOR_WEEK_DAYS, PRIOR_MONTH_DAYS, PRIOR_YEAR_DAYS, PRIOR_YEAR2_DAYS,
					DISPLAY_FORMAT, COLOR_SCALE)
			values (Source.STATE, PageType, PageOrder, MetricName, Source.Yesterday, priorWeek, priorMonth, priorYear, priorYear2,
				pifYesterday, pifPriorWeek, pifPriorMonth, pifPriorYear, pifPriorYear2,
				yesterdayDays, priorWeekDays, priorMonthDays, priorYearDays, priorYear2Days,
				displayFormat, colorScale);


			merge Periscope_Data.dbo.HUDDLE_WEBPAGE as Target
			using (select STATE, 'Claims' as PageType,
			METRIC as metricName,
			STUFF((
				SELECT ',' + '{' + char(34) + 'd' + char(34) + ':' + char(34) + convert(varchar(10),DATA_DATE) + char(34) + ',' + char(34) + 'n' + char(34) + ':' + convert(varchar(20),METRIC_NUMBER) + '}'
				FROM Periscope_Data.dbo.HUDDLE_DATA b
				where HUDDLE_METRIC like concat('% ',a.METRIC)
					and b.STATE = c.STATE
					and HUDDLE_METRIC like concat(case @i when 0 then 'Daily' when 1 then 'Weekly' when 2 then 'Monthly' end,'%')
					and DATA_DATE between case when @i = 2 then @prior_year2 else @prior_year end and @dateAsOf
				order by data_date desc
				FOR XML PATH('')), 1, 1, '')  as distrib, 
			case when @i = 0 then
				STUFF((
				SELECT ',' + '{' + char(34) + 'd' + char(34) + ':' + char(34) + convert(varchar(10),DATA_DATE) + char(34) + ',' + char(34) + 'n' + char(34) + ':' + convert(varchar(20),METRIC_NUMBER) + '}'
				FROM Periscope_Data.dbo.HUDDLE_DATA b
				where HUDDLE_METRIC like concat('% ',a.METRIC)
					and b.STATE = c.STATE
					and HUDDLE_METRIC like concat(case @i when 0 then 'Daily' when 1 then 'Weekly' when 2 then 'Monthly' end,'%')
					and DATA_DATE between case when @i = 2 then @prior_year2 else @prior_year end and @dateAsOf
					and datepart(dw,DATA_DATE) = datepart(dw,@dateAsOf)
				order by data_date desc
				FOR XML PATH('')), 1, 1, '')
			else null end as otherDistrib
			from (select 'PIP Severity' as METRIC union all select 'PD Severity' as METRIC union all select 'BI Severity' as METRIC union all select 'CMP Severity' as METRIC union all select 'COL Severity' as METRIC) a
			join (select distinct STATE from Periscope_Data.dbo.HUDDLE_DATA) c on 1 = 1
			) as Source
			on @i < 3 and PAGE_TYPE = PageType and METRIC_NAME = metricName and Target.STATe = Source.STATE
			when matched then 
				update set DAY_DISTRIBUTION = case when @i = 0 then distrib else DAY_DISTRIBUTION end,
							WEEKDAY_DISTRIBUTION = case when @i = 0 then otherDistrib else WEEKDAY_DISTRIBUTION end,
							WEEK_DISTRIBUTION = case when @i = 1 then distrib else WEEK_DISTRIBUTION end,
							MONTH_DISTRIBUTION = case when @i = 2 then distrib else MONTH_DISTRIBUTION end;

		set @i = @i + 1;
	end;
delete from Periscope_Data.dbo.HUDDLE_WEBPAGE
where STATE = 'FL' and METRIC_NAME in ('APEX-STD Sales','APEX-LTD Sales','EDGE-STD Sales','EDGE-LTD Sales','PLUS-STD Sales');
delete from Periscope_Data.dbo.HUDDLE_WEBPAGE
where STATE = 'TX' and METRIC_NAME in ('WIN Sales','OPT Sales','SEL Sales','ICN Sales');
update Periscope_Data.dbo.HUDDLE_WEBPAGE
set DATA_DATE = @date_used;
GO

