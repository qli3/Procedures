USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[wh_insrt_tx_policy_processing]    Script Date: 12/15/2017 4:42:03 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[wh_insrt_tx_policy_processing] 
   @Dt datetime
   AS
   INSERT INTO dbo.wh_policy_processing (Reporting_Date, Category, Report_name, Avg_period, Avg_num)
   /* Daily Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Late payments' Report_name,'Daily_Avg' Avg_period,
count(policyId) Avg
from periscope_data.dbo.wh_late_payments_policy_processing_v
where late_payment_date=convert(date,@Dt- 1)
union all  
/* Weekly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Late payments' Report_name, 'Weekly_Avg',
Round(convert(decimal,count(policyId))/5,2)
from periscope_data.dbo.wh_late_payments_policy_processing_v
where late_payment_date between   convert(date,@Dt-8) and convert(date,@Dt-1)
union all 
/* Monthly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Late payments' Report_name, 'Monthly_Avg',
Round(convert(decimal,count(policyId))/20,2)
from periscope_data.dbo.wh_late_payments_policy_processing_v
where late_payment_date between   convert(date,@Dt-29) and convert(date,@Dt-1)
union all  
/* Yearly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Late payments' Report_name,'Yearly_Avg',
Round(convert(decimal,count(policyId))/(select Periscope_Data.dbo.fn_wh_countweekdays(@Dt-366,@Dt-1)),2)
from periscope_data.dbo.wh_late_payments_policy_processing_v
where convert(date,late_payment_date) between convert(date,@Dt-366) and convert(date,@Dt-1)

union all 

/* Daily Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Refund policies' Report_name,'Daily_Avg' Avg_period,
convert(decimal,count(policyID)) Avg
from periscope_data.dbo.wh_refund_pol_policy_processing_v
where refunded_dt=convert(date,@Dt- 1)
union all  
/* Weekly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Refund policies' Report_name,'Weekly_Avg',
Round(convert(decimal,count(policyID))/5,2)
from periscope_data.dbo.wh_refund_pol_policy_processing_v
where refunded_dt between   convert(date,@Dt-8) and convert(date,@Dt-1)
union all  
/* Monthly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Refund policies' Report_name,'Monthly_Avg',
Round(convert(decimal,count(policyID))/20,2)
from periscope_data.dbo.wh_refund_pol_policy_processing_v
where refunded_dt between   convert(date,@Dt-29) and convert(date,@Dt-1)
union all  
/* Yearly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Refund policies' Report_name,'Yearly_Avg',
Round(convert(decimal,count(policyID))/(select Periscope_Data.dbo.fn_wh_countweekdays(@Dt-366,@Dt-1)),2)
from periscope_data.dbo.wh_refund_pol_policy_processing_v
where convert(date,refunded_dt) between convert(date,@Dt-366) and convert(date,@Dt-1)

union all  

/* Daily Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Non_Pay_Cancellation' Report_name,'Daily_Avg' Avg_period,
convert(decimal,count(policy_Id)) Avg
from periscope_data.dbo.wh_non_pay_cancel_pol_policy_processing_v
where cancelled_Dt=convert(date,@Dt- 1)
union all  
/* Weekly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Non_Pay_Cancellation' Report_name,'Weekly_Avg',
Round(convert(decimal,count(policy_Id))/5,2)
from periscope_data.dbo.wh_non_pay_cancel_pol_policy_processing_v
where cancelled_Dt between   convert(date,@Dt-8) and convert(date,@Dt-1)
union all  
/* Monthly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Non_Pay_Cancellation' Report_name,'Monthly_Avg',
Round(convert(decimal,count(policy_Id))/20,2)
from periscope_data.dbo.wh_non_pay_cancel_pol_policy_processing_v
where cancelled_Dt between   convert(date,@Dt-29) and convert(date,@Dt-1)
union all  
/* Yearly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Non_Pay_Cancellation' Report_name,'Yearly_Avg',
Round(convert(decimal,count(policy_Id))/(select Periscope_Data.dbo.fn_wh_countweekdays(@Dt-366,@Dt-1)),2)
from periscope_data.dbo.wh_non_pay_cancel_pol_policy_processing_v
where convert(date,cancelled_Dt) between convert(date,@Dt-366) and convert(date,@Dt-1)

union all  

/* Daily Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,
'Reinstated policy' Report_name,
'Daily_Avg' Avg_period,
convert(decimal,count(policyId)) Avg
from periscope_data.dbo.wh_reinstated_pol_policy_processing_v
where Reinstated_date=convert(date,@Dt- 1)
union all  
/* Weekly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,
'Policy Processing' Category,
'Reinstated policy' Report_name,'Weekly_Avg',
Round(convert(decimal,count(policyId))/5,2)
from periscope_data.dbo.wh_reinstated_pol_policy_processing_v
where Reinstated_date between   convert(date,@Dt-8) and convert(date,@Dt-1)
union all  
/* Monthly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,
'Policy Processing' Category,
'Reinstated policy' Report_name,'Monthly_Avg',
Round(convert(decimal,count(policyId))/20,2)
from periscope_data.dbo.wh_reinstated_pol_policy_processing_v
where Reinstated_date between   convert(date,@Dt-29) and convert(date,@Dt-1)
union all  
/* Yearly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,
'Reinstated policy' Report_name,'Yearly_Avg',
Round(convert(decimal,count(policyId))/(select Periscope_Data.dbo.fn_wh_countweekdays(@Dt-366,@Dt-1)),2)
from periscope_data.dbo.wh_reinstated_pol_policy_processing_v
where convert(date,Reinstated_date) between convert(date,@Dt-366) and convert(date,@Dt-1)


union all  

/* Daily Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Bank Payments' Report_name,'Daily_Avg' Avg_period,
convert(decimal,count(policyID)) Avg
from periscope_data.dbo.wh_bank_payment_policy_processing_v
where bc_payment_dt=convert(date,@Dt- 1)
union all  
/* Weekly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Bank Payments' Report_name,'Weekly_Avg',
Round(convert(decimal,count(policyID))/5,2)
from periscope_data.dbo.wh_bank_payment_policy_processing_v
where bc_payment_dt between   convert(date,@Dt-8) and convert(date,@Dt-1)
union all  
/* Monthly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Bank Payments' Report_name,'Monthly_Avg',
Round(convert(decimal,count(policyID))/20,2)
from periscope_data.dbo.wh_bank_payment_policy_processing_v
where bc_payment_dt between   convert(date,@Dt-29) and convert(date,@Dt-1)
union all  
/* Yearly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Bank Payments' Report_name,'Yearly_Avg',
Round(convert(decimal,count(policyID))/(select Periscope_Data.dbo.fn_wh_countweekdays(@Dt-366,@Dt-1)),2)
from periscope_data.dbo.wh_bank_payment_policy_processing_v
where convert(date,bc_payment_dt) between convert(date,@Dt-366) and convert(date,@Dt-1)


union all  

/* Daily Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'CC Payments' Report_name,'Daily_Avg' Avg_period,
convert(decimal,count(policyID)) Avg
from periscope_data.dbo.wh_cc_payment_policy_processing_v
where cc_payment_dt=convert(date,@Dt- 1)
union all  
/* Weekly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'CC Payments' Report_name,'Weekly_Avg',
Round(convert(decimal,count(policyID))/5,2)
from periscope_data.dbo.wh_cc_payment_policy_processing_v
where cc_payment_dt between   convert(date,@Dt-8) and convert(date,@Dt-1)
union all  
/* Monthly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'CC Payments' Report_name,'Monthly_Avg',
Round(convert(decimal,count(policyID))/20,2)
from periscope_data.dbo.wh_cc_payment_policy_processing_v
where cc_payment_dt between   convert(date,@Dt-29) and convert(date,@Dt-1)
union all  
/* Yearly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'CC Payments' Report_name,'Yearly_Avg',
Round(convert(decimal,count(policyID))/(select Periscope_Data.dbo.fn_wh_countweekdays(@Dt-366,@Dt-1)),2)
from periscope_data.dbo.wh_cc_payment_policy_processing_v
where convert(date,cc_payment_dt) between convert(date,@Dt-366) and convert(date,@Dt-1)

union all  

/* Daily Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Nsfd policy' Report_name,'Daily_Avg' Avg_period,
convert(decimal,count(suspenseID)) Avg
from periscope_data.dbo.wh_nsfd_pol_policy_processing_v
where nsfd_date=convert(date,@Dt- 1)
union all  
/* Weekly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Nsfd policy' Report_name,'Weekly_Avg',
Round(convert(decimal,count(suspenseID))/datepart(dw,@Dt-1),2)
from periscope_data.dbo.wh_nsfd_pol_policy_processing_v
where nsfd_date between   convert(date,@Dt-8) and convert(date,@Dt-1)
union all  
/* Monthly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Nsfd policy' Report_name,'Monthly_Avg',
Round(convert(decimal,count(suspenseID))/datepart(d,@Dt-1),2)
from periscope_data.dbo.wh_nsfd_pol_policy_processing_v
where nsfd_date between   convert(date,@Dt-29) and convert(date,@Dt-1)
union all  
/* Yearly Avg*/
select 
case when datepart(dw,@Dt)=2 then convert(date,@Dt-3)
else
convert(	date,@Dt- 1) end Reporting_Date,'Policy Processing' Category,'Nsfd policy' Report_name,'Yearly_Avg',
Round(convert(decimal,count(suspenseID))/(select Periscope_Data.dbo.fn_wh_countweekdays(@Dt-366,@Dt-1)),2)
from periscope_data.dbo.wh_nsfd_pol_policy_processing_v
where convert(date,nsfd_date) between convert(date,@Dt-366) and convert(date,@Dt-1);
GO

