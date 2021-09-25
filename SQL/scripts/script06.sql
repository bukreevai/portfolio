select distinct 
       a.model,
       t.flights_count,
       round((t.flights_count::decimal / count(f.flight_id) over ()::decimal) * 100, 2) as flights_procent
  from flights as f
  join ( select f2.aircraft_code,
                count (f2.flight_id) as flights_count
           from flights f2
       group by f2.aircraft_code) as t
    on t.aircraft_code = f.aircraft_code 
  join aircrafts as a
    on a.aircraft_code = f.aircraft_code;
    