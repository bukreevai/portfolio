  select a.city,
         count(a.airport_code)
    from airports as a
group by a.city
  having count(a.airport_code) > 1; 