
select * into #zoneP
from pricing..tblPricingZoneItemHistory
where itemid in (select distinct item_id from pricing.dbo.promotional_retail_prices );

select store_id, item_no,1 qty, cast(sales_dollars/(units_sold + lbs_sold) as decimal(6,2)) edwRetailPrice, day_date,'' expires ,'edw' source
,sales_dollars,units_sold , lbs_sold
into #cteEDW
from datasync..edw_sales_daily
where (units_sold + lbs_sold)<>0 ;
CREATE INDEX i1 ON #cteEDW (store_id);
CREATE INDEX i2 ON #cteEDW (item_no);


with ctePricing as (
Select distinct store_id, item_id , qty_for_price , price jda_price, effective_date , expiration_date ,'p' source from pricing.dbo.promotional_retail_prices
union all
select distinct *, 'e' from pricing..everyday_retail_prices

)

,


cteStoreZones as (
SELECT   cm_.customer, cm_1.price_zone_exception, cm_1.effective_date 
FROM     salshared.dbo.cm_customer_master cm_
         INNER JOIN salshared.dbo.cm_customer_price_zone cm_1 
			ON cm_.cm_customer_master_id=cm_1.cm_customer_master_id

),
 cteEventPlannerPromos                     AS ( 
                    SELECT --SUNDAY - MONDAY
           oi.item_no
      ,    s.store_id
      ,    o.offer_retail_multiple
      ,    o.offer_retail
      ,    dateadd(DAY, -3, e.ad_effective_date) ad_effective_date --e.ad_effective_date
      ,    e.ad_expiration_date
        FROM promotion_event_planner..event                 e
             INNER JOIN promotion_event_planner..stores     s
                        ON s.event_id = e.event_id
             INNER JOIN promotion_event_planner..offer      o
                        ON o.event_id = e.event_id
             INNER JOIN promotion_event_planner..offer_item oi
                        ON o.offer_id = oi.offer_id
        WHERE
              o.approved = 1
          AND e.ad_effective_date < '08/01/2019'
          AND e.ad_expiration_date > getdate() - (365 * 3)
          AND e.ad_effective_date IS NOT NULL
          AND oi.item_no < 100000
--and oi.item_no in(71250,10000)
    UNION
    SELECT -- WEDNESDAY - TUESDAY
           oi.item_no
      ,    s.store_id
      ,    o.offer_retail_multiple
      ,    o.offer_retail
      ,    e.ad_effective_date
      ,    e.ad_expiration_date
        FROM promotion_event_planner..event                 e
             INNER JOIN promotion_event_planner..stores     s
                        ON s.event_id = e.event_id
             INNER JOIN promotion_event_planner..offer      o
                        ON o.event_id = e.event_id
             INNER JOIN promotion_event_planner..offer_item oi
                        ON o.offer_id = oi.offer_id
        WHERE
              o.approved = 1
          AND e.ad_effective_date < '08/01/2019'
          AND e.ad_expiration_date > getdate() - (365 * 3)
          AND e.ad_effective_date IS NOT NULL
          AND oi.item_no < 100000
--and oi.item_no in(71250,10000)
    UNION
    SELECT DISTINCT
        oi.item_no
      , os.store_id
      , o.offer_retail_multiple
      , o.offer_retail
      , ed.ad_effective_date
      , ed.ad_expiration_date
        FROM promotion_event_planner..event                          e
             INNER JOIN promotion_event_planner..event_date          ed
                        ON e.event_id = ed.event_id
             INNER JOIN promotion_event_planner..stores              s
                        ON s.event_id = e.event_id
                            AND s.event_date_id = ed.event_date_id
             INNER JOIN promotion_event_planner..offer               o
                        ON o.event_id = e.event_id
             INNER JOIN promotion_event_planner..offer_stores        os
                        ON os.offer_id = o.offer_id
                            AND s.store_id = os.store_id
             INNER JOIN promotion_event_planner..offer_item          oi
                        ON o.offer_id = oi.offer_id
             INNER JOIN promotion_event_planner..offer_pricing       op
                        ON op.offer_id = o.offer_id
             INNER JOIN promotion_event_planner..offer_pricing_item  opi
                        ON opi.offer_pricing_id = op.offer_pricing_id
             INNER JOIN promotion_event_planner..offer_pricing_store ops
                        ON ops.offer_pricing_id = op.offer_pricing_id
                            AND ops.store_id = os.store_id
        WHERE
              o.approved = 1
          AND ed.ad_effective_date >= '08/01/2019'
          AND oi.item_no < 100000
--and oi.item_no in(71250,10000)
            ) 

, cteEvaluate as (
select * 
,(select min(edwRetailPrice) maxPrice from #cteEDW where item_no=p.item_id and day_date between p.effective_Date and p.expiration_date and p.store_id=store_id ) edwMinRetail
,(select max(edwRetailPrice) maxPrice from #cteEDW where item_no=p.item_id and day_date between p.effective_Date and p.expiration_date and p.store_id=store_id ) edwMaxRetail
,(select cast(min(retailprice/QuantityForPrice) as money) from pricing..tblPricingStoreItemHistory
		where itemid=p.item_id and storeid=p.store_id and EffectiveDate between convert(varchar,p.effective_Date,112) and convert (varchar,p.expiration_date,112)) minSIP
,(select cast(max(retailprice/QuantityForPrice) as money) from pricing..tblPricingStoreItemHistory
		where itemid=p.item_id and storeid=p.store_id and EffectiveDate between convert(varchar,p.effective_Date,112) and convert (varchar,p.expiration_date,112)) maxSIP
,(select min(RetailPrice/QuantityForPrice)  from
	#zoneP
	where zoneid in(select zoneid from cteStoreZones where customer=p.store_id) 
	and effectivedate between convert(varchar,p.effective_Date,112) and convert (varchar,p.expiration_date,112)) minZP
,(select max(RetailPrice/QuantityForPrice)  from
	#zoneP
	where zoneid in(select zoneid from cteStoreZones where customer=p.store_id) 
	and effectivedate between convert(varchar,p.effective_Date,112) and convert (varchar,p.expiration_date,112)) maxZP
,(select min(cast(offer_retail/offer_retail_multiple as decimal(6,2))) from cteEventPlannerPromos where item_no=p.item_id and store_id=p.store_id and ad_effective_date between p.effective_Date and p.expiration_date) minPromoRetail
,(select max(cast(offer_retail/offer_retail_multiple as decimal(6,2))) from cteEventPlannerPromos where item_no=p.item_id and store_id=p.store_id and ad_effective_date between p.effective_Date and p.expiration_date) maxPromoRetail
from ctePricing p
--where store_id=253
)
,
cte1 as (
select store_id,item_id,qty_for_price,jda_price,effective_date,expiration_date,source
,edwMinRetail,edwMaxRetail
,minSIP,maxSIP
,minZP,maxZP
,minPromoRetail
,maxPromoRetail 
from cteEvaluate
--where  item_id=71250
), cte2 as (
select store_id, item_id, count(jda_price) jdaPrices,count(maxZP) zonePrices1 ,count(minZP) zonePrices2 
,count(maxSIP) sipPrices1 ,count(minSIP) sipPrices2
from cte1
group by store_id, item_id
) 
select * from cte2 
where item_id between 70000 and 80000
and (jdaPrices<>zonePrices1 and jdaPrices<>zonePrices2)
--where (abs(jda_price-edwMinRetail)>.02  and abs(jda_Price-edwMaxRetail)>.02)
--order by effective_date
--select * from pricing..tblPricingZoneItem 
--where itemid=71250 and zoneid=31


--delete from datasync..edw_sales_daily where lbs_sold+units_sold=0
