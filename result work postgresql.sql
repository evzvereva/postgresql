-- 1. В каких городах больше одного аэропорта?

select city, count(city) as count_airports -- название городов и количество их совпадений
from airports a -- берем данные для подсчета из таблицы airports
group by a.city -- группируем по названию города
having count(city) > 1; -- условие, если количетсво совпадений по названию города больше одного

-- 2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета? (Применить подзапрос)

select a1.city, a1.airport_name -- название города и название аэропорта
from flights f -- берем данные из таблицы flights
left join aircrafts a on a.aircraft_code = f.aircraft_code -- объединяем таблицу aircrafts с моделями самолетов, а также данными по дальности перелетов
left join airports a1 on a1.airport_code = f.departure_airport -- объединяем таблицу airports, в которой указаны названия аэропорта, а также их код
group by a.model, a1.city, a1.airport_name -- группируем по названию модели, а также по названию аэропорта
having a.model = (
	select model
	from aircrafts a
	order by "range" desc 
	limit 1
	); -- в условии указываем что модель должна быть равна полученному значению из подзапроса таблицы aircrafts, в которой находим модель с 
	-- максимальной дальностью полета. 

-- 3. Вывести 10 рейсов с максимальным временем задержки вылета. Использовать оператор LIMIT.

select f.flight_no, a.airport_name, a.city, (actual_departure - scheduled_departure) as "flight delay" -- номер рейса, названиеаэропорта, название города отправления, подсчет времени задержки полета. 
from flights f -- берем данные из таблицы flights 
left join airports a on a.airport_code = f.departure_airport -- для получения названия городов и аэропорта, присоеднием таблицу airports по названию кода.
where (actual_departure - scheduled_departure) is not null -- условие, что задержка по времени не будет содержать null
order by (actual_departure - scheduled_departure) desc -- сортируем по убыванию
limit 10; -- ставим лимит 10 рейсов

-- 4. Были ли брони, по которым не были получены посадочные талоны? Верный тип JOIN.

select t.book_ref, t.passenger_name, -- номер бронирования, имя и фамилия пассажира
	case when bp.ticket_no is null then 'Нет посадочного талона' -- проверяем есть ли посадочный талон
		else 'Посадочный талон получен' 
	end as "Посадочный талон получен/не получен"
from tickets t -- берем данные из таблицы tickets
left join boarding_passes bp on bp.ticket_no = t.ticket_no -- объединяем таблицу boarding_passes с tickets по номеру посадочного талона
where bp.boarding_no is null; -- условие, значение посадочного билет null


/* 5. Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня. 
- Оконная функция
- Подзапросы или/и cte. */

-- explain analyze 17799.64
with a1 as (
	select f.aircraft_code, f.departure_airport, f.actual_departure,  
	count(bp.seat_no)  as "занято мест"
	from boarding_passes bp -- подсчитываем количество занятых мест в самолете из таблицы boarding_passes bp
	join flights f on f.flight_id = bp.flight_id -- присоединяем таблицу flights к boarding_passes bp по flight_id 
	where status = 'Arrived' or status = 'Departed' -- статус должен быть равен 'Arrived' или 'Departed', так как нужно подсчитать количество вывезенных пассажиров
	group by f.aircraft_code, f.actual_departure, f.departure_airport
	), a2 as (
	select distinct aircraft_code, count(seat_no) over (partition by aircraft_code) as "общее количество мест в самолете"
	from seats -- получаем данные из таблицы seats, в которой подсчитываем общее количество мест в каждой модели самолета
	)
select a1.departure_airport, a1.actual_departure, a1.aircraft_code, 
(coalesce(a2."общее количество мест в самолете", 0.) - coalesce(a1."занято мест", 0.)) as "свободные места в самолете",
(coalesce(a2."общее количество мест в самолете", 0.) - coalesce(a1."занято мест", 0.)) / coalesce(a2."общее количество мест в самолете", 0.) * 100 as "% отношение к общему количеству мест в самолете"
/* Выводим код аэропорта, с которого был вылет, 
 * фактическое время вылета, код самолета, 
 * количество занятых мест, 
 * общее количество мест в каждой модели самолета, 
 * подсчитываем количество свободных мест, 
 * затем считаем отношение свободных к общему количеству мест в %, 
 * добавляем столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день*/
from a1
join a2 on a2.aircraft_code = a1.aircraft_code
group by a1.departure_airport, a1.actual_departure, a1."занято мест", a1.aircraft_code, a2."общее количество мест в самолете"
order by a1.departure_airport asc;

-- 6. Найдите процентное соотношение перелетов по типам самолетов от общего количества. Подзапрос или окно. Оператор ROUND.

select distinct aircraft_code, 
count(flight_no) over (partition by aircraft_code) as "количество перелетов по модели", 
count(flight_no) over () as "общее количество перелетов по всем моделям самолетов", 
round(((count(flight_no) over (partition by aircraft_code))::numeric / (count(flight_no) over ())::numeric * 100), 3) as "отношение перелетов по типам самолетов к общему количеству"
from flights -- берем данные из таблицы flights, так как здесь находится вся информация по перелетам и моделям самолетов для подсчета
where status = 'Arrived' or status = 'Departed';

/* 8. Между какими городами нет прямых рейсов? 
- Декартово произведение в предложении FROM
- Самостоятельно созданные представления (если облачное подключение, то без представления)
- Оператор EXCEPT */

create materialized view between_city_no_direct_flights as -- создаем материализованное представление
	select a1.city as departure_city, a2.city as arrival_city -- выводим города аэропортов вылета и прибытия
	from airports a1
	cross join airports a2 -- используем декартово произведение чтобы использовать в дальнейшем для вывода городов, между которомы нет прямых рейсов
	where a1.city <> a2.city -- ставим условие, что первый столбец и второй с городами неравны 
	except 
	select a1.city as departure_city, a2.city as arrival_city
	from flights f -- выводим данные с учетом присеодиненной таблицы городов
	join airports a1 on a1.airport_code = f.departure_airport -- чтобы узнать к какому городу вылета относится код аэропорта
	join airports a2 on a2.airport_code = f.arrival_airport -- чтобы узнать к какому городу прибытия относится код аэропорта
with no data;

refresh materialized view between_city_no_direct_flights;

select *
from between_city_no_direct_flights; -- выводим данные городов, между которомы нет прямых рейсов

/* 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, 
 * обслуживающих эти рейсы. Использовать:
 * - Оператор RADIANS или использование sind/cosd
 * - CASE */

select distinct f.departure_airport, 
	f.arrival_airport, 
	air."range" as air_range,  
	round((acos(sin(radians(a1.latitude)) * sin(radians(a2.latitude)) + cos(radians(a1.latitude)) * cos(radians(a2.latitude)) * 
		cos(radians(a1.longitude - a2.longitude))) * 6371)::numeric, 2) as distance, -- рассчитываем расстояние между аэропортами
	case when air."range" > round((acos(sin(radians(a1.latitude)) * sin(radians(a2.latitude)) + cos(radians(a1.latitude)) * cos(radians(a2.latitude)) * 
		cos(radians(a1.longitude - a2.longitude))) * 6371)::numeric, 2) then 'Самолет долетит'
	else 'Самолет не долетит'
end as "Долетит/Не долетит" -- сравниваем дальность самолета и расстояние между аэропортами
from flights f -- берем данные из таблицы flights f
join airports a1 on a1.airport_code = f.departure_airport -- соединяем таблицу airports для определения широты и долготы каждого аэропорта в таблице flights
join airports a2 on a2.airport_code = f.arrival_airport -- соединяем таблицу airports для определения широты и долготы каждого аэропорта в таблице flights
join aircrafts air on air.aircraft_code = f.aircraft_code  -- соединяем таблицу aircrafts для получения дальности самолета
where f.departure_airport <> f.arrival_airport; -- ставим условие, что первый столбец и второй с городами неравны, получая города между которыми прямой рейс
