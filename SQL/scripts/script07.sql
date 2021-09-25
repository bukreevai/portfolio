  with flight_economy (flight_id, economy_amount) as 
       (select tf.flight_id,
               tf.amount 
          from ticket_flights tf 
         where tf.fare_conditions = 'Economy')
select distinct
       f.flight_no,
       f.departure_airport,
       f.arrival_airport
  from flights as f 
  join (select tf.flight_id,
               tf.amount as business_amount
          from ticket_flights tf 
         where tf.fare_conditions = 'Business') as fb
     on fb.flight_id = f.flight_id
   join flight_economy as fe
     on fe.flight_id = f.flight_id
  where fe.economy_amount > fb.business_amount;
