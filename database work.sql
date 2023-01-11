-- 1. Выводим уникальные названия городов из таблицы городов:

select distinct city
from city;

-- 2. Города, названия которых начинается на "L" и заканчиваются на "a", и названия не содержат пробелов:

select city
from city
where city like 'L%a' and city not like '% %';

/* 3. Получаем информацию по платежам, которые выполнялись в промежуток с 17 июня 2005 года по 19 июня 2005 года включительно и стоимость которых превышает 1.00, 
отсортированных по дате платежа: */

select payment_id, 
	payment_date, 
	amount
from payment
where payment_date::date between '17-06-2005' and '19-06-2005' and amount > '1.00'
order by payment_date;

-- 4. Выводим информацию о 10-ти последних платежах за прокат фильмов:

select payment_id, 
	payment_date, 
	amount
from payment 
order by payment_date desc 
limit 10;

/* 5. Выводим информацию по покупателям:
 * Фамилия и имя (в одной колонке через пробел)
 * Электронная почта
 * Длина значения поля email
 * Дата последнего обновления записи о покупателе (без времени)
Каждой колонке задаем наименование на русском языке. */

select concat(last_name, ' ', first_name) as "Фамилия и имя", 
	email as "Электронная почта", 
	length(email) as "Длина Email", 
	date(last_update) as "Дата" 
from customer;

/* 6. Выводим одним запросом только активных покупателей, имена которых KELLY или WILLIE. 
Все буквы в фамилии и имени из верхнего регистра должны быть переведены в нижний регистр. */

select lower(last_name) as last_name, 
	lower(first_name) as first_name, 
	active
from customer
where first_name = 'KELLY' or first_name = 'WILLIE';

/* 7. Выводим одним запросом информацию о фильмах, у которых рейтинг “R” и стоимость аренды указана от 0.00 до 3.00 включительно, 
а также фильмы c рейтингом “PG-13” и стоимостью аренды больше или равной 4.00: */

select film_id, 
	title, 
	description, 
	rating, 
	rental_rate
from film
where rating = 'R' and rental_rate >= 0.00 and rental_rate <= 3.00 or rating = 'PG-13' and rental_rate >= 4.00;

-- 8. Получаем информацию о трёх фильмах с самым длинным описанием фильма:

select film_id, 
	title, 
	description
from film
order by character_length(description) desc
limit 3;

-- 9. Выведим Email каждого покупателя, разделив значение Email на 2 отдельных колонки:

select customer_id, 
	email, 
	split_part(email, '@', 1) as "Email before @", 
	split_part(email, '@', 2) as "Email after @"
from customer;

-- 10. Доработаем запрос из предыдущего задания, скорректируем значения в новых колонках: первая буква должна быть заглавной, остальные строчными.

select customer_id, 
	email, 
	split_part(concat(upper(substring(email, 1, 1)), 
	substring(lower(email), 2)), '@', 1) as "Email before @", 
	concat(upper(substring(split_part(email, '@', 2), 1, 1)), 
	lower(substring(split_part(email, '@', 2), 2))) as "Email after @"
from customer;
