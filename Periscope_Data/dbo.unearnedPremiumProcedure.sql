USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[unearnedPremiumProcedure]    Script Date: 12/15/2017 4:41:53 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[unearnedPremiumProcedure]
	@dateUsed date
as
	declare @sql_code nvarchar(1000);
	if object_id('dbo.Unearned','U') is not null
		drop table dbo.Unearned;

	create table dbo.Unearned
		(PolicyNum varchar(25), Treaty varchar(15), WrittenPremium decimal(12,2),
			EarnedPremium decimal(12,2), UnearnedPremium decimal(12,2),
			primary key(policyNum, Treaty));

	insert into dbo.Unearned 
	select *
	from (select policyNum, '' as treaty,
sum(changeInFullTermPremium) as writtenPremium,
sum(coalesce(round(changeInFullTermPremium*
	case when convert(date,transactionDate) > @dateUsed
		or convert(date,dateeffective) > @dateUsed then null
	else
		coalesce(round(cast((1 + datediff(day,dateeffective,
			case when @dateUsed >expirationDate 
		then expirationDate else @dateUsed end)) as decimal)/
		cast(nullif((1+datediff(day,dateeffective,expirationDate)),0) as decimal),4),1) end,2),0)) as earnedPremium,
sum(coalesce(round(changeInFullTermPremium*
	case when convert(date,transactionDate) > @dateUsed
		or convert(date,dateeffective) > @dateUsed then null
	else
		case when round(cast((datediff(day,@dateUsed,
			case when @dateUsed <expirationDate 
		then expirationDate else @dateUsed end)) as decimal)/
		cast(nullif((1+datediff(day,dateeffective,expirationDate)),0) as decimal),4) > 1
		then 1 else
		round(cast((datediff(day,@dateUsed,
			case when @dateUsed <expirationDate 
		then expirationDate else @dateUsed end)) as decimal)/
		cast(nullif((1+datediff(day,dateeffective,expirationDate)),0) as decimal),4)
		end end,2),0)) as unearnedPremium
from [Windhaven_Report].dbo.CoveragePremium
join [Windhaven_Report].dbo.Policy on Policy.policyID = CoveragePremium.policyId
where transactionDate <= @dateUsed
group by policyNum) b
where UnearnedPremium <> 0
;

	set @sql_code = concat('select * ','from dbo.Unearned');
	execute sp_executesql @sql_code;
GO

