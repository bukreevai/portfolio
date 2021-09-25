select distinct 
       r.departure_airport_name,
       r2.arrival_airport_name 
  from routes r, routes r2        
 where r.departure_airport_name <> r2.arrival_airport_name 
except 
select distinct
	   r3.departure_airport_name,
	   r3.arrival_airport_name 
  from routes r3 