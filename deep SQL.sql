/* Основная часть
База данных: если подключение к облачной базе, то создаёте новую схему с префиксом в виде фамилии, название должно быть на латинице в нижнем регистре и таблицы создаете в этой новой схеме, если подключение к локальному серверу, то создаёте новую схему и в ней создаёте таблицы.

Задание 1. Спроектируйте базу данных, содержащую три справочника:
· язык (английский, французский и т. п.);
· народность (славяне, англосаксы и т. п.);
· страны (Россия, Германия и т. п.).
Две таблицы со связями: язык-народность и народность-страна, отношения многие ко многим. Пример таблицы со связями — film_actor.
Требования к таблицам-справочникам:
· наличие ограничений первичных ключей.
· идентификатору сущности должен присваиваться автоинкрементом;
· наименования сущностей не должны содержать null-значения, не должны допускаться дубликаты в названиях сущностей.
Требования к таблицам со связями:
· наличие ограничений первичных и внешних ключей. */

create table country (
	country_id serial primary key,
	country_name varchar(100) not null unique
);

create table nation (
	nation_id serial primary key,
	nation_name varchar(100) not null unique
);

create table language (
	language_id serial primary key,
	language_name varchar(100) not null unique
);

create table country_nation (
	country_id int references country(country_id),
	nation_id int references nation(nation_id),
	primary key(country_id, nation_id) 
);

create table nation_language (
	nation_id int references nation(nation_id),
	language_id int references language(language_id),
	primary key(language_id, nation_id) 
);

insert into country (country_name)
values ('Россия'), ('США'), ('Великобритания'), ('Германия'), ('Франция');

insert into nation (nation_name)
values ('Русские'), ('Американцы'), ('Англичане'), ('Немцы'), ('Французы');

insert into language (language_name)
values ('Русский'), ('Американский'), ('Английский'), ('Немецкий'), ('Французский');

insert into country_nation (country_id, nation_id)
values (1, 1), (2, 2), (3, 3), (4, 4), (5, 5);

insert into nation_language (nation_id, language_id)
values (1, 1), (2, 2), (3, 3), (4, 4), (5, 5);

/* Дополнительная часть

Задание 1. Создайте новую таблицу film_new со следующими полями:
· film_name — название фильма — тип данных varchar(255) и ограничение not null;
· film_year — год выпуска фильма — тип данных integer, условие, что значение должно быть больше 0;
· film_rental_rate — стоимость аренды фильма — тип данных numeric(4,2), значение по умолчанию 0.99;
· film_duration — длительность фильма в минутах — тип данных integer, ограничение not null и условие, что значение должно быть больше 0.
Если работаете в облачной базе, то перед названием таблицы задайте наименование вашей схемы. */

create table film_new (
	film_new_id serial primary key,
	film_name varchar(255) not null,
	film_year int check(film_year > 0),
	film_rental_rate numeric(4,2) not null default 0.99,
	film_duration int not null check(film_duration > 0)
);

/* Задание 2. Заполните таблицу film_new данными с помощью SQL-запроса, где колонкам соответствуют массивы данных:
· film_name — array[The Shawshank Redemption, The Green Mile, Back to the Future, Forrest Gump, Schindler’s List];
· film_year — array[1994, 1999, 1985, 1994, 1993];
· film_rental_rate — array[2.99, 0.99, 1.99, 2.99, 3.99];
· film_duration — array[142, 189, 116, 142, 195]. */

insert into film_new (film_name, film_year, film_rental_rate, film_duration)
values 
(unnest(array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindler’s List']), 
unnest(array[1994, 1999, 1985, 1994, 1993]), 
unnest(array[2.99, 0.99, 1.99, 2.99, 3.99]), 
unnest(array[142, 189, 116, 142, 195]));

-- Задание 3. Обновите стоимость аренды фильмов в таблице film_new с учётом информации, что стоимость аренды всех фильмов поднялась на 1.41.

update film_new set film_rental_rate = film_rental_rate + 1.41;

-- Задание 4. Фильм с названием Back to the Future был снят с аренды, удалите строку с этим фильмом из таблицы film_new.

delete from film_new 
where film_name = 'Back to the Future';

-- Задание 5. Добавьте в таблицу film_new запись о любом другом новом фильме.

insert into film_new (film_name, film_year, film_rental_rate, film_duration)
values ('Tall order', 1998, 0, 133);

-- Задание 6. Напишите SQL-запрос, который выведет все колонки из таблицы film_new, а также новую вычисляемую колонку «длительность фильма в часах», округлённую до десятых.

select *, round(film_duration / 60::numeric, 1) as movie_duration_in_hours
from film_new

-- Задание 7. Удалите таблицу film_new.

drop table film_new;
