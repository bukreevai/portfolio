select actual_departure - scheduled_departure as departure_delay,
       *
  from flights as f
  where actual_departure is not null
order by (actual_departure - scheduled_departure) desc
   limit 10;