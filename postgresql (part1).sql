/* Задание 1. Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:

Пронумеруйте все платежи от 1 до N по дате
Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате
Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна быть сперва по дате платежа, а затем по сумме платежа от наименьшей к большей
Пронумеруйте платежи для каждого покупателя по стоимости платежа от наибольших к меньшим так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе. */

with t1 as (select customer_id, 
				payment_id, 
				payment_date, 
				row_number() over (order by payment_date) as column_1 
			from payment),
	t2 as (select payment_id, 
				row_number() over (partition by customer_id order by payment_date) as column_2 
			from payment),
	t3 as (select payment_id, 
			sum(amount) over (partition by customer_id order by payment_date, sum(amount) asc) as column_3
			from payment p
			group by p.customer_id, p.payment_date, p.amount, p.payment_id),
	t4 as (select payment_id, 
				rank() over (partition by customer_id order by amount desc) as column_4
			from payment)	
select t1.customer_id, 
	t1.payment_id, 
	t1.payment_date, 
	t1.column_1, 
	t2.column_2, 
	t3.column_3, 
	t4.column_4
from t1
join t2 on t2.payment_id = t1.payment_id
join t3 on t3.payment_id = t1.payment_id
join t4 on t4.payment_id = t1.payment_id;

/* Задание 2. С помощью оконной функции выведите для каждого покупателя стоимость платежа 
 * и стоимость платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате. */

select customer_id, 
	payment_id, 
	payment_date, 
	amount,
	lag(amount, 1, 0.) over (partition by customer_id order by payment_date) as last_amount
from payment;

-- Задание 3. С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.

select customer_id, 
	payment_id, 
	payment_date, 
	amount, 
	amount - lead(amount, 1, 0.) over (partition by customer_id order by payment_date) as difference
from payment;

-- Задание 4. С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

select customer_id, 
	payment_id,
	payment_date,
	amount
from (
	select customer_id, 
		payment_id,
		payment_date,
		row_number () over(partition by customer_id order by payment_date desc) as row_date,
		amount
	from payment) t 
where t.row_date = 1
order by customer_id;

/* Дополнительная часть
 * 
 * Задание 1. С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
 * с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) с сортировкой по дате.
 */
	
select s.staff_id,
	p.payment_date::date,
	sum(p.amount) as sum_amount,
	sum(sum(p.amount)) over (partition by s.staff_id order by p.payment_date::date) as sum
from staff s 
join payment p on p.staff_id = s.staff_id 
where p.payment_date::date between '2005-08-01' and '2055-08-31'
group by s.staff_id, p.payment_date::date;

/*Задание 2. 20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал дополнительную 
* скидку на следующую аренду. С помощью оконной функции выведите всех покупателей, которые в день проведения акции получили скидку.
*/

select *
from (
	select customer_id, 
		payment_date,
		row_number () over (order by payment_date) as r
	from payment p 
	where payment_date::date = '2005-08-20') t
where t.r % 100 = 0;

/*Задание 3. Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
· покупатель, арендовавший наибольшее количество фильмов;
· покупатель, арендовавший фильмов на самую большую сумму;
· покупатель, который последним арендовал фильм.
*/

with t1 as (select c.address_id, 
				concat(c.first_name, ' ', c.last_name) as name_,
				i.film_id,
				p.amount,
				p.payment_date, c2.country_id,
				c3.country,
				row_number () over (partition by c3.country order by p.payment_date desc) r3
			from customer c 
			join rental r on r.customer_id = c.customer_id 
			join payment p on p.customer_id = c.customer_id and r.rental_id = p.rental_id 
			join inventory i on i.inventory_id = r.inventory_id 
			join address a on a.address_id = c.address_id 
			join city c2 on c2.city_id = a.city_id 
			join country c3 on c2.country_id = c3.country_id 
			),
			t2 as (
				select country, name_ ,
				row_number () over (partition by country order by count(film_id) desc) r1,
				row_number () over (partition by country order by sum(amount) desc) r2
				from t1
				group by country, name_
				order by 1
			)
select t1.country as "Страна",
	t2.name_ as "Покупатель с наибольшим количеством фильмов",
	t22.name_ as "Покупатель с наибольшей суммой",
	t1.name_ as "Покупатель, который последним арендовал"
from t1
join t2 on t2.country = t1.country and t2.r1 = 1
join t2 t22 on t22.country = t1.country and t22.r2 = 1
where t1.r3 = 1
order by t1.country;



