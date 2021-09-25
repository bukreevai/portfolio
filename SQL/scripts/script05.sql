select f.flight_id,
       f.flight_no,
       csa.seats_count,
       bp.pass_count,
       csa.seats_count - bp.pass_count as free_seats,
       round(((csa.seats_count::decimal - bp.pass_count::decimal) / csa.seats_count::decimal) * 100.0, 2) as free_seats_procent,
       f.departure_airport,
       f.actual_departure,
       sum(bp.pass_count) over (partition by f.departure_airport, f.actual_departure::date order by f.actual_departure rows between unbounded preceding and current row) as passengers_total
  from flights as f 
  join (  select b.flight_id,
                 count(flight_id) as pass_count
            from boarding_passes as b
        group by b.flight_id) as bp
    on bp.flight_id = f.flight_id 
  join (  select s.aircraft_code,
                 count (seat_no) as seats_count
            from seats as s
        group by s.aircraft_code) as csa
    on f.aircraft_code = csa.aircraft_code;
   