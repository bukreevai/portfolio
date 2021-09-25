     with airport_coords (airport_code, latitude, longitude) as 
  (select a2.airport_code,
          a2.latitude * (3.14 / 180),
          a2.longitude * (3.14 / 180)
          from airports a2)
   select distinct
          r.departure_airport_name,
          r.arrival_airport_name,
          round((acos(sin(ac.latitude) * sin(ac2.latitude) + cos(ac.latitude) * cos(ac2.latitude) * cos(ac.longitude - ac2.longitude)) * 6372)::numeric, 2) as distance,
          air.range as aircraft_range,
          round((100 -((acos(sin(ac.latitude) * sin(ac2.latitude) + cos(ac.latitude) * cos(ac2.latitude) * cos(ac.longitude - ac2.longitude)) * 6372)::numeric / air."range") * 100), 2) as aircraft_reserve_pocent
     from routes r 
left join routes r2
       on r.departure_airport_name = r2.arrival_airport_name
      and r.arrival_airport_name = r2.departure_airport_name
     join airport_coords as ac
       on ac.airport_code = r.departure_airport
     join airport_coords as ac2
       on ac2.airport_code = r.arrival_airport
     join aircrafts as air
       on air.aircraft_code = r.aircraft_code
    where r.departure_airport_name > r.arrival_airport_name
 