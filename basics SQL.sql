-- Задание 1. Выведите для каждого покупателя его адрес, город и страну проживания.

select concat(last_name, ' ', first_name) as "Customer name", 
	address, 
	city, 
	country
from customer c 
left join address a on a.address_id = c.address_id
left join city c2 on c2.city_id = a.city_id 
left join country c3 on c3.country_id = c2.country_id;

-- Задание 2. С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select s.store_id as "ID магазина", 
	count(c.customer_id) as "Количество покупателей", 
	c2.city as "Город", 
	concat(s2.last_name, ' ', s2.first_name) as "Имя сотрудника"
from store s
left join customer c on c.store_id = s.store_id
left join address a on s.address_id = a.address_id 
left join city c2 on a.city_id = c2.city_id 
left join staff s2 on s2.store_id = s.store_id
group by s.store_id, c2.city_id, s2.staff_id 
having count(c.customer_id) > 300;

-- Задание 3. Выведите топ-5 покупателей, которые взяли в аренду за всё время наибольшее количество фильмов.

select concat(c.last_name, ' ', c.first_name) as "Фамилия и имя покупателя", 
	count(p.amount) as "Количество фильмов"
from customer c 
join rental r on r.customer_id = c.customer_id
join payment p on p.customer_id = c.customer_id and p.rental_id = r.rental_id
group by c.customer_id 
order by count(p.amount) desc 
limit 5;

/* Задание 4. Посчитайте для каждого покупателя 4 аналитических показателя:

- количество взятых в аренду фильмов;
- общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа);
- минимальное значение платежа за аренду фильма;
- максимальное значение платежа за аренду фильма. */

select concat(c.last_name, ' ', c.first_name) as "Фамилия и имя покупателя", 
	count(i.film_id) as "Количество фильмов", 
	round(sum(p.amount), 0) as "Общая стоимость платежей", 
	min(p.amount) as "Минимальная стоимость платежа", 
	max(p.amount) as "Максимальная стоимость платежа"
from customer c 
left join rental r on r.customer_id = c.customer_id
left join payment p on p.customer_id = c.customer_id and p.rental_id = r.rental_id
join inventory i on i.inventory_id = r.inventory_id 
group by c.customer_id;

/* Задание 5. 
 * Используя данные из таблицы городов, составьте одним запросом всевозможные пары городов так, 
 * чтобы в результате не было пар с одинаковыми названиями городов.
 * Для решения необходимо использовать декартово произведение. */

select c1.city as "Город 1", 
	c2.city as "Город 2"
from city c1
cross join city c2
where c1.city != c2.city;

/* Задание 6. Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и дате возврата (поле return_date), 
 * вычислите для каждого покупателя среднее количество дней, за которые он возвращает фильмы. */

select c.customer_id, 
	round(avg(date(r.return_date) - date(r.rental_date)), 2) as "Среднее количество дней на возврат"
from customer c 
left join rental r on r.customer_id = c.customer_id 
group by c.customer_id
order by c.customer_id;

/*Дополнительная часть
 * 
 * Задание 1. Посчитайте для каждого фильма, 
 * сколько раз его брали в аренду, а также общую стоимость аренды фильма за всё время. */

select f.title as "Название фильма",   
	rating as "Рейтинг", 
	c.name as "Жанр", 
	release_year as "Год выпуска", 
	l."name" as "Язык", 
	count(r.rental_id) as "Количество аренд", 
	sum(p.amount)
from film f
left join film_category fc on fc.film_id = f.film_id 
left join category c on c.category_id = fc.category_id
left join "language" l on l.language_id = f.language_id 
left join inventory i on i.film_id = f.film_id
left join rental r on r.inventory_id = i.inventory_id
join payment p on p.rental_id = r.rental_id 
group by f.film_id, c.category_id, l.language_id 
order by title asc;

-- Задание 2. Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые ни разу не брали в аренду.

select f.title as "Название фильма", 
	rating as "Рейтинг", 
	c.name as "Жанр", 
	release_year as "Год выпуска", 
	l."name" as "Язык", 
	count(r.rental_id) as "Количество аренд", 
	sum(p.amount) as "Общая стоимость аренды"
from film f
left join film_category fc on fc.film_id = f.film_id 
left join category c on c.category_id = fc.category_id
left join "language" l on l.language_id = f.language_id 
left join inventory i on i.film_id = f.film_id
left join rental r on r.inventory_id = i.inventory_id
left join payment p on p.rental_id = r.rental_id 
group by f.film_id, c.category_id, l.language_id 
having count(r.rental_id) = 0
order by title asc;

/* Задание 3. Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку «Премия». 
 * Если количество продаж превышает 7 300, то значение в колонке будет «Да», иначе должно быть значение «Нет». */

select s.staff_id, 
	count(p.staff_id) as "Количество продаж",
	(case
		when count(p.staff_id) > 7300 then 'Да'
		else 'Нет премии'
	end) as "Премия"	
from payment p 
join staff s on s.staff_id = p.staff_id
group by s.staff_id;
