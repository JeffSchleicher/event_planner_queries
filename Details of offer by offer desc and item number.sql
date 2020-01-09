select 
o.offer_desc
, os.store_id
, ed.ad_effective_date
, ed.ad_expiration_date
, oi.item_no
, mst.item_desc
, opsid.current_store_unit_cost, sg.distcenter
from promotion_event_planner..offer o
inner join promotion_event_planner..offer_stores os
on o.offer_id = os.offer_id
inner join promotion_event_planner..offer_pricing op
on op.offer_id = o.offer_id
inner join promotion_event_planner..offer_pricing_store ops
on op.offer_pricing_id = ops.offer_pricing_id
and ops.store_id = os.store_id
inner join promotion_event_planner..offer_pricing_store_item_detail opsid
on opsid.offer_pricing_id = op.offer_pricing_id
and opsid.store_id = ops.store_id
inner join promotion_event_planner..event_date ed
on o.event_id = ed.event_id
inner join promotion_event_planner..stores s
on o.event_id = s.event_id
and os.store_id = s.store_id
and ed.event_date_id = s.event_date_id
inner join promotion_event_planner..offer_item oi
on o.offer_id = oi.offer_id
inner join whse..imitmmst mst
on mst.item_no = oi.item_no

left join stores..tblStoregeneral sg
on sg.storeid=os.store_id

where op.current_store_unit_cost < .5
and o.event_id = 833
and o.offer_desc like '%fluffy%';


select * from
whse..imitmloc where item_no=44858
