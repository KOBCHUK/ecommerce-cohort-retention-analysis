select *
from cohort_users_raw cur 
limit 10;

select *
from cohort_events_raw cer 
limit 1;


--Завдання_1. Очищення та стандартизація дат реєстрації користувачів
--Проміжна версія1: Витягування дати без часу та первинна заміна розділювачів
select
	cur.user_id ,
	cur.signup_datetime ,
	replace(replace(TRIM(split_part(cur.signup_datetime , ' ', 1)), '.', '-'), '/', '-') as clean_date_str
from cohort_users_raw cur; 

--Проміжна версія2: перевірки форматів дат для визначення шаблону
select
	cur.user_id ,
	cur.signup_datetime ,
	split_part(replace(replace(TRIM(split_part(cur.signup_datetime ,' ', 1)),'.','-'),'/','-'),'-', 3) as year_part
from cohort_users_raw cur ;

--Фінальна версія запиту: очищення, конвертація у TIMESTAMP через CASE та TO_DATE
with users_cleaned as (
	select
		--1. Основні атрибути користувача
		cur.user_id ,
		cur.full_name ,
		cur.email ,
		cur.country ,
		cur.signup_source ,
		cur.signup_device ,
		cur.promo_signup_flag ,
		--Зберігаю сире значення для контролю/порівняння
		cur.signup_datetime as signup_datetime_raw,
		-- Очищення рядка дати та конвертація у TIMESTAMP:
		-- - TRIM + SPLIT_PART(..., ' ', 1): видаляємо компоненти часу та пробіли
		-- - REPLACE(REPLACE()): уніфікуємо деліметри(крапки та похилі риски міняємо на дефіс '-')
		-- - CASE: оцінюємо довжину року (третій елемент після розділення дефісом)
		-- - TO_DATE: перетворюємо у календарну дату за відповідним форматом і приводимо до TIMESTAMP
		case 
			-- Якщо рік містить 2 цифри 
			when length(split_part(replace(replace(TRIM(split_part(cur.signup_datetime , ' ', 1)), '.', '-'), '/', '-'), '-', 3)) = 2 
                then to_date(
                        replace(replace(TRIM(split_part(cur.signup_datetime , ' ', 1)), '.', '-'), '/', '-'), 
                        'DD-MM-YY'
                     )::timestamp 
			-- Якщо рік містить 4 цифри
            else  to_date(
                    replace(replace(TRIM(split_part(cur.signup_datetime , ' ', 1)), '.', '-'), '/', '-'), 
                    'DD-MM-YYYY'
                 )::timestamp         
		end as signup_timestamp
		
	from cohort_users_raw cur 
)
--Фінальна вибірка підготовлених даних з CTE
select *
from users_cleaned 
order by user_id asc;

--Завдання_2. Очищення та стандартизація дат подій у таблиці cohort_events_raw
--Проміжна версія: Первинна перевірка відокремлення дати від часу та зміна розділювачів
select
cer.event_id ,
cer.user_id ,
cer.event_type ,
cer.revenue ,
cer.event_datetime as event_datetime_raw,
replace(replace(TRIM(split_part(cer.event_datetime ,' ', 1)), '.', '-'),'/', '-') as clean_event_date_str
from cohort_events_raw cer; 

-- Фінальна версія запиту
with events_cleaned as (
	select
		cer.event_id ,
		cer.user_id ,
		cer.event_type ,
		cer.revenue ,
		cer.event_datetime as event_datetime_raw,
	case
		when length(split_part(replace(replace(TRIM(split_part(cer.event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)) = 2 
                then to_date(
                        replace(replace(TRIM(split_part(cer.event_datetime , ' ', 1)), '.', '-'), '/', '-'), 
                        'DD-MM-YY'
                     )::timestamp 
			-- Якщо рік містить 4 цифри
            else  to_date(
                    replace(replace(TRIM(split_part(cer.event_datetime , ' ', 1)), '.', '-'), '/', '-'), 
                    'DD-MM-YYYY'
                 )::timestamp         
		end as event_timestamp
	from cohort_events_raw cer 
)
select 
	event_id ,
	user_id,
	event_type,revenue ,
	event_datetime_raw ,
	event_timestamp 	
from events_cleaned
order by event_id asc;

-- Завдання_3: Обʼєднання таблиць, розрахунок month_offset та фільтрація
with users_cleaned as (
	select
		cur.user_id ,
		cur.full_name ,
		cur.email ,
		cur.country ,
		cur.signup_source ,
		cur.signup_device ,
		cur.promo_signup_flag ,
		case 
			when length(split_part(replace(replace(TRIM(split_part(cur.signup_datetime , ' ', 1)), '.', '-'), '/', '-'), '-', 3)) = 2 
                then to_date(
                        replace(replace(TRIM(split_part(cur.signup_datetime , ' ', 1)), '.', '-'), '/', '-'), 
                        'DD-MM-YY'
                     )::timestamp 
            else  to_date(
                    replace(replace(TRIM(split_part(cur.signup_datetime , ' ', 1)), '.', '-'), '/', '-'), 
                    'DD-MM-YYYY'
                 )::timestamp         
		end as signup_timestamp	
	from cohort_users_raw cur 
),
events_cleaned as (
	select
		cer.event_id ,
		cer.user_id ,
		cer.event_type ,
		cer.revenue ,
		cer.event_datetime as event_datetime_raw,
	case
		when length(split_part(replace(replace(TRIM(split_part(cer.event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)) = 2 
                then to_date(
                        replace(replace(TRIM(split_part(cer.event_datetime , ' ', 1)), '.', '-'), '/', '-'), 
                        'DD-MM-YY'
                     )::timestamp 
            else  to_date(
                    replace(replace(TRIM(split_part(cer.event_datetime , ' ', 1)), '.', '-'), '/', '-'), 
                    'DD-MM-YYYY'
                 )::timestamp         
		end as event_timestamp
	from cohort_events_raw cer 
)
-- Проміжна версія: Перевірка розрахунку month_offset а формування когорт
/*select
	events_cleaned.event_id ,
	users_cleaned.user_id ,
	to_char(users_cleaned.signup_timestamp, 'YYYY-MM') as signup_cohort, 
	to_char(events_cleaned.event_timestamp, 'YYYY-MM')	 as event_month,
	(EXTRACT(YEAR FROM events_cleaned.event_timestamp) - EXTRACT(YEAR FROM users_cleaned.signup_timestamp)) * 12 + (EXTRACT(MONTH FROM events_cleaned.event_timestamp) - EXTRACT(MONTH FROM users_cleaned.signup_timestamp)) AS month_offset
from events_cleaned
join users_cleaned on events_cleaned.user_id = users_cleaned.user_id;*/ 
--Фінальна вибірка 
select
	events_cleaned.event_id ,
	users_cleaned.user_id ,
	users_cleaned.full_name ,
	users_cleaned.country ,
	users_cleaned.signup_source ,
	users_cleaned.signup_device ,
	users_cleaned.promo_signup_flag ,
	events_cleaned.event_type ,
	events_cleaned.revenue ,
	--форматування дат у формат "Рік-Місяць" (YYYY-MM)
	to_char(users_cleaned.signup_timestamp, 'YYYY-MM') as signup_cohort, 
	to_char(events_cleaned.event_timestamp, 'YYYY-MM') as event_month,
	--Розрахунок стажу користувачів в місяцях (month_offset)
	(extract(year from events_cleaned.event_timestamp) - extract(year from users_cleaned.signup_timestamp)) * 12 + (extract(month from events_cleaned.event_timestamp) - extract(month from users_cleaned.signup_timestamp)) as month_offset
from events_cleaned
join users_cleaned on events_cleaned.user_id = users_cleaned.user_id
--фільтрація відповідно до умов завдання
where users_cleaned.signup_timestamp  is not null 
	and events_cleaned.event_timestamp is not null
	and events_cleaned.event_type is not null 
	and events_cleaned.event_type <> 'test_event'
order by events_cleaned.event_id::integer asc;

--Завдання_4. Агрегація даних для когортної матриці
--1. CTE users_cleaned & events_cleaned — очищення та конвертація дат.
--2. CTE base_joined_data — об'єднання таблиць, розрахунок month_offset та фільтрація від тестових/порожніх подій.
--3. Фінальний select — фільтрація періоду активності (2025-01 ... 2025-06), групування за промо-прапором, когортою та зсувом, підрахунок унікальних користувачів (COUNT DISTINCT).
--Проміжна версія: Перевірка підрахунку унікальних користувачів без сортування.
/*select 
	users_cleaned.promo_signup_flag ,
	to_char(users_cleaned.signup_timestamp, 'YYYY-MM') as cohort_month,
	(extract(year from events_cleaned.event_timestamp) - extract(year from users_cleaned.signup_timestamp)) * 12 + (extract(month from events_cleaned.event_timestamp) - extract(month from users_cleaned.signup_timestamp)) as month_offset,
	count(distinct users_cleaned.user_id) as users_total
from events_cleaned
join users_cleaned on events_cleaned.user_id  = users_cleaned.user_id 
where to_char(events_cleaned.event_timestamp, 'YYYY-MM' ) between '2025-01' and '2025-06'
group by 1,2,3;*/

--Фінальная версія запиту
with users_cleaned as (
	select
		cur.user_id ,
		cur.full_name ,
		cur.email ,
		cur.country ,
		cur.signup_source ,
		cur.signup_device ,
		cur.promo_signup_flag ,
		case 
			when length(split_part(replace(replace(TRIM(split_part(cur.signup_datetime , ' ', 1)), '.', '-'), '/', '-'), '-', 3)) = 2 
                then to_date(
                        replace(replace(TRIM(split_part(cur.signup_datetime , ' ', 1)), '.', '-'), '/', '-'), 
                        'DD-MM-YY'
                     )::timestamp 
            else  to_date(
                    replace(replace(TRIM(split_part(cur.signup_datetime , ' ', 1)), '.', '-'), '/', '-'), 
                    'DD-MM-YYYY'
                 )::timestamp         
		end as signup_timestamp	
	from cohort_users_raw cur 
),
events_cleaned as (
	select
		cer.event_id ,
		cer.user_id ,
		cer.event_type ,
		cer.revenue ,
		cer.event_datetime as event_datetime_raw,
	case
		when length(split_part(replace(replace(TRIM(split_part(cer.event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)) = 2 
                then to_date(
                        replace(replace(TRIM(split_part(cer.event_datetime , ' ', 1)), '.', '-'), '/', '-'), 
                        'DD-MM-YY'
                     )::timestamp 
            else  to_date(
                    replace(replace(TRIM(split_part(cer.event_datetime , ' ', 1)), '.', '-'), '/', '-'), 
                    'DD-MM-YYYY'
                 )::timestamp         
		end as event_timestamp
	from cohort_events_raw cer 
),
base_joined_data as (
select
	events_cleaned.event_id ,
	users_cleaned.user_id ,
	users_cleaned.promo_signup_flag ,
	to_char(users_cleaned.signup_timestamp, 'YYYY-MM') as cohort_month, 
	to_char(events_cleaned.event_timestamp, 'YYYY-MM') as activity_month,
	--Розрахунок стажу користувачів в місяцях (month_offset)
	(extract(year from events_cleaned.event_timestamp) - extract(year from users_cleaned.signup_timestamp)) * 12 + (extract(month from events_cleaned.event_timestamp) - extract(month from users_cleaned.signup_timestamp)) as month_offset
from events_cleaned
join users_cleaned on events_cleaned.user_id = users_cleaned.user_id
--фільтрація відповідно до умов завдання
where users_cleaned.signup_timestamp  is not null 
	and events_cleaned.event_timestamp is not null
	and events_cleaned.event_type is not null 
	and events_cleaned.event_type <> 'test_event'
)
--фінальний агрегований select
select
	promo_signup_flag ,
	cohort_month ,
	month_offset ,
	count(distinct user_id) as users_total
from base_joined_data 
--обмеження періоду спостереження активності: січень-червень 2025 року
where activity_month between '2025-01' and '2025-06'
group by
	promo_signup_flag ,
	cohort_month ,
	month_offset 
order by
	promo_signup_flag asc,
	cohort_month asc,
	month_offset asc;



