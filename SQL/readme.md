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
# script 06
>Найдите процентное соотношение перелетов по типам самолетов от общего количества.
```sql
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
```
## описание
Сперва таблица `flights` соединяется с подзапросом, в котором подсчитывается количество полетов по каждому самолету. Соединение происходит по коду самолёта. Далее полученный датасет соединяется с таблицей `aircrafts` по коду самолёта для получения модели самолёта. И для каждой модели самолёта происходит расчёт процентов с помощью оконной функции по всем строкам датасета.
# script 07
>Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
```sql
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

```
## описание
В CTE запросе из таблицы `ticket_flights` выбираются все билеты с классом обслуживания «Эконом». Далее таблица `flights` соединяется с подзапросом, в котором из таблицы `ticket_flights` выбираются все билеты с классом обслуживания «Бизнесс», и CTE запросом. Далее  выводятся только уникальные рейсы, в которых билет  эконом класса был дороже чем бизнес-класса. 
# script 08
>Между какими городами нет прямых рейсов?
```sql
select distinct 
       r.departure_airport_name,
       r2.arrival_airport_name 
  from routes r, routes r2        
 where r.departure_airport_name <> r2.arrival_airport_name 
except 
select distinct
	   r3.departure_airport_name,
	   r3.arrival_airport_name 
  from routes r3;

```
## описание
Из декартового произведения  материализованного представления `routes` на само себя выбираются пары городов отправления и городов прибытия,  за исключением получившихся пар, где город отправления = город прибытия. Из полученного дата сета исключаются те пары, которые уже есть в материализованном представлении и выбираются только уникальные значения.  
# script 09
>Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов в самолетах, обслуживающих эти рейсы
```sql
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

```
## описание
В CTE запросе происходит подготовка перевод градусов в радианы из таблицы airports.  Для исключения из материализованного представления routes обратных маршрутов производится объединение его с самим собой по условию – город отправления из левого датасета равен городу прибытия в правом датасете и город прибытия из левого датасета равен городу прибытия в правом датасете. 
Полученный датасет объединяется дважды с CTE запросом для получения соответсвующих радиан для каждого города в паре город отправления – город прибытия. Так же происходит соединение с таблицей aircrafts для получения максимальной дальности полёта самолета, исполняющего рейс. 
Далее рассчитываются вычисляемые поля: 
* Расстояние между городами 
* Процент запаса хода самолёта, выполняющего данный рейс 
