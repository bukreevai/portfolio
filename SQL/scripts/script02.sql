  with max_range_aircraft (code, "range") as (
select a.aircraft_code,
       a."range" 
  from aircrafts as a
 where a."range"  = (select max(a2."range")
                       from aircrafts a2 )) 
select distinct
       mra."range" as fly_range,
       f.flight_no,
       f.departure_airport as airport_code,
       air.airport_name
  from flights as f
  join max_range_aircraft mra
       on f.aircraft_code = mra.code  
  join airports as air
       on air.airport_code = f.departure_airport
 order by f.flight_no;