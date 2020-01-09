--count number of stores and items per event
--runs in about 3 minutes
SELECT 
        e.event_id, count (distinct s.store_id) store_count, count(distinct oi.item_no)
--into #cteEventPlannerPromosWithoutPrimaryItemTranformation 
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
          AND e.ad_expiration_date > '2016-08-17'
          AND e.ad_effective_date IS NOT NULL


group by e.event_id