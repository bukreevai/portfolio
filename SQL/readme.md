# SQL
Скрипты были подготовлены на учёбной базе "Авиаперевозки" (версию не помню).
Описание базы: https://postgrespro.ru/education/demodb
## script 01
>В каких городах больше одного аэропорта
```sql
 select a.city, 
        count(a.airport_code) 
   from airports as a 
  group by a.city 
 having count(a.airport_code) > 1; 
```
### Описание 
Происходит выборка городов из таблицы `airports`, происходит подсчёт количества аэропортов по каждому городу и фильтрация по количеству городов 
## script 02
>В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
```sql
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
```
### описание
В CTE запросе из таблицы `aircrafts` отбираются самолёты, которые имеют наибольшее расстояние полёта. Отбор происходит  путем формирования подзапроса к этой же таблице и выборки из неё максимального значения с помощью функции `max()` 

Далее из таблицы `flights` отбираются уникальные рейсы путем соединения с CTE запросом по полю `aircraft_code`. Потом полученный результат соединяется с таблицей `airports` по условию `airports.airport_code = flightsю.departure_airport`. 

Результат сортируется по номеру рейса. 
## script 03 
>Вывести 10 рейсов с максимальным временем задержки вылета 
```sql
select actual_departure - scheduled_departure as departure_delay, 
        * 
   from flights as f 
  where actual_departure is not null 
  order by departure_delay desc 
  limit 10; 
```
### описание
По таблице `flights` рассчитывается фактическое время задержки рейса (актуальный вылет – вылет по расписанию), происходит упорядочивание по убыванию по этому расчёту и отбираются первые 10 записей 
## script 04
>Были ли брони, по которым не были получены посадочные талоны? 
```sql
select distinct  
          t.book_ref, 
          bp.boarding_no     
     from tickets as t 
left join boarding_passes as bp 
       on bp.ticket_no = t.ticket_no 
    where bp.boarding_no is null;  
```
### описание
Происходит левое соединение таблицы `tickets`  (билеты) с таблицей `boarding_passes`  (посадочные талоны) по номеру билета (`bp.ticket_no = t.ticket_no`). Далее происходит фильтрация полученных записей по пустому полю «номер посадочного талона» (`boarding_no`). 
## script 05 
>Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете. Добавьте столбец с накопительным итогом - суммарное количество вывезенных пассажиров из аэропорта за день. Т.е. в этом столбце должна отражаться сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах за сегодняшний день 
```sql
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
```
### описание
Таблица `flights` соединяется с подзапросом, в котором по таблице `boarding_passes`, подсчитывается количество посадочных талонов по каждому рейсу. Соединение происходит по идентифактору рейса. Далее полученный датасет объединяется с подзапросом, в котором по таблице `seats`,  рассчитывается общее количество мест в каждой модели самолета. Соединение происходит по коду модели.  

Далее вычисляются поля:  
* Количество свободных мест в самолете (`csa.seats_count - bp.pass_count`); 
* Количество свободных мест делится на общее количество мест и умножается на 100, округляется до двух знаков после запятой. 
* По окну аэропорт отправления и день вылета рассчитывается накопительный итог (`rows between unbounded preceding and current row`) по занятым местам. 