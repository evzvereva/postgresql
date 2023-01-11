-- Задание 1. Напишите SQL-запрос, который выводит всю информацию о фильмах со специальным атрибутом “Behind the Scenes”. */

-- explain analyze -- 77.50
select film_id, title, special_features
from film
where 'Behind the Scenes' = any(special_features);

/* Задание 2. Напишите ещё 2 варианта поиска фильмов с атрибутом “Behind the Scenes”, используя другие функции или операторы языка SQL для поиска 
значения в массиве. */ 

-- explain analyze -- 67.50
select film_id, title, special_features
from film
where special_features && array['Behind the Scenes'];

-- explain analyze -- 67.50
select film_id, title, special_features
from film
where special_features @> array['Behind the Scenes'];

/* Задание 3. Для каждого покупателя посчитайте, сколько он брал в аренду фильмов со специальным атрибутом “Behind the Scenes”.
Обязательное условие для выполнения задания: используйте запрос из задания 1, помещённый в CTE. */

-- explain analyze -- 678.47
with cte as (
	select film_id
	from film
	where special_features && array['Behind the Scenes'])
	select distinct r.customer_id, count(cte.film_id) as film_count
	from cte
	left join inventory i on i.film_id = cte.film_id
	left join rental r on r.inventory_id = i.inventory_id
	group by r.customer_id
	order by r.customer_id asc;

/* Задание 4. Для каждого покупателя посчитайте, сколько он брал в аренду фильмов со специальным атрибутом “Behind the Scenes”.
Обязательное условие для выполнения задания: используйте запрос из задания 1, помещённый в подзапрос, который необходимо использовать 
для решения задания. */

-- explain analyze -- 678.47
select distinct r.customer_id, count(t.film_id) as film_count
from (
	select film_id
	from film
	where special_features && array['Behind the Scenes']) as t
left join inventory i on i.film_id = t.film_id
left join rental r on r.inventory_id = i.inventory_id
group by r.customer_id
order by r.customer_id asc;

-- Задание 5. Создайте материализованное представление с запросом из предыдущего задания и напишите запрос для обновления материализованного представления.

create materialized view count_film_customer as
	select distinct r.customer_id, count(t.film_id) as film_count
	from (
		select film_id
		from film
		where special_features && array['Behind the Scenes']) as t
	left join inventory i on i.film_id = t.film_id
	left join rental r on r.inventory_id = i.inventory_id
	group by r.customer_id
	order by r.customer_id asc;
with no data;

refresh materialized view count_film_customer;

-- explain analyze -- 10.00
select *
from count_film_customer;

/* Задание 6. С помощью explain analyze проведите анализ скорости выполнения запросов из предыдущих заданий и ответьте на вопросы:
с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания, поиск значения в массиве происходит быстрее;
какой вариант вычислений работает быстрее: с использованием CTE или с использованием подзапроса. */

--С операторами &&, @> получается быстрее запрос выполняется. 
--По поводу СТЕ и использование позапроса у меня получилось одинаково.

-- Задание 7. Используя оконную функцию, выведите для каждого сотрудника сведения о первой его продаже.

select staff_id, 
	film_id,
	amount,
	payment_date,
	last_name,
	first_name
from 
	(select s.staff_id,
		f.film_id,
		f.title,
		p.amount,
		p.payment_date,
		c.last_name,
		c.first_name,
		row_number () over (partition by s.staff_id order by p.payment_date) as r
	from staff s 
	join payment p on p.staff_id = s.staff_id
	join rental r on r.rental_id = p.rental_id 
	join inventory i on i.inventory_id = r.inventory_id 
	join film f on f.film_id = i.film_id
	join customer c on c.customer_id = p.customer_id) t
where t.r = 1

/* Задание 8. Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
* день, в который арендовали больше всего фильмов (в формате год-месяц-день);
* количество фильмов, взятых в аренду в этот день;
* день, в который продали фильмов на наименьшую сумму (в формате год-месяц-день);
* сумму продажи в этот день.
*/

with t1 as 
	(select s.store_id,
		s2.staff_id
	from store s 
	join staff s2 on s2.store_id  = s.store_id),
	t2 as ( select sum(p.amount) as sum_amount,
				t1.store_id,
				p.payment_date::date as payment_date,
				row_number () over (partition by t1.store_id order by sum(p.amount)) as r1
			from payment p 
			join t1 on p.staff_id = t1.staff_id
			group by p.payment_date::date, t1.store_id),
	t3 as (select t1.store_id, 
			r.rental_date::date,
			count(i.film_id) as count_film,
			row_number () over (partition by t1.store_id order by count(i.film_id) desc) as r2
		from t1
		join rental r on r.staff_id = t1.staff_id
		join inventory i on i.inventory_id = r.inventory_id
		group by r.rental_date::date, t1.store_id)
select t3.store_id,
	t3.rental_date,
	t3.count_film,
	t2.payment_date,
	t2.sum_amount
from t3
join t2 on t2.store_id = t3.store_id and t2.r1 = 1
where t3.r2 = 1;


