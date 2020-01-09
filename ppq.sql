--on corporate sql server
with cteDatesToProcess as (
select cal_date from stores..sal_fiscal_calendar where calendar_week_end 
	in(
		select distinct calendar_week_end from stores..sal_fiscal_calendar
		where cal_date>=cast(getdate()-14 as date)  and cal_date<=cast(getdate()-7 as date)
	) 
)

, cteItemStoreList as (
 select distinct item_no, store_id
 from datasync.dbo.edw_sales_daily s
inner join cteDatesToProcess dtp
on s.day_date=dtp.cal_date

							
 union
 select distinct item_no, store_id
 from datasync.dbo.edw_movement_daily m
 inner join cteDatesToProcess dtp
 on m.day_date=dtp.cal_date
								
 )

 --insert into datasync..ppq_sales_count
 select sl.item_no,sl.store_id
 , count(distinct sd.day_date) day_count
 , coalesce(sum(sd.units_sold + sd.lbs_sold ),0) sales_units,0 mvmt_units
 --, coalesce(sum(md.case_pack_lbs_sold * movement ) ,0) mvmt_units
 from cteItemStoreList sl
 inner join datasync.dbo.edw_sales_daily sd
 on sd.item_no=sl.item_no
 and sd.store_id=sl.store_id
 where sd.day_date >  dateadd(dd,-91,getdate())

 group by sl.item_no,sl.store_id
