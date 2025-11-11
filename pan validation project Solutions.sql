create table pan(
pan_numbers text
)
select * from pan

-- DATA CLEANING

-- 1. Identify and handle missing data
select * from pan where pan_numbers is null --965

-- 2.check the duplicates
select pan_numbers, count(*) from pan where pan_numbers is not null
group by pan_numbers
having count(*)> 1  --5

--3. Handling trail/leading spaces
select * from pan where pan_numbers<>trim(pan_numbers) --9

--4. correct uppercase
select * from pan where pan_numbers <> upper(pan_numbers) --990

-- ALL IN ONE
create table pan1 as
select distinct upper(trim(pan_numbers)) from pan
where pan_numbers is not null and trim (pan_numbers)<>''

select * from pan1

-- DATA VALIDATION

-- function to check adjacent characters are repitative so 
-- it should return true if adjacent character are adjacent 
-- else return false

create or replace function fn_check_adjacent_repetition(p_str text)
returns boolean
language plpgsql
as $$
begin
	for i in 1 .. (length(p_str) - 1)
	loop
		if substring(p_str, i, 1) = substring(p_str, i+1, 1)
		then 
			return true;
		end if;
	end loop;
	return false;
end;
$$
select fn_check_adjacent_repetition('AABCD')

-- Function to check if characters are sequencial such as ABCDE, LMNOP, XYZ etc. 
-- Returns true if characters are sequencial else returns false
create or replace function fn_check_sequence(p_str TEXT)
returns BOOLEAN
language plpgsql
as $$
declare
    i INT;
begin
    for i in 1 .. (length(p_str) - 1) loop
        if ASCII(substring(p_str from i + 1 for 1)) - ASCII(substring(p_str from i for 1)) <> 1 then
            return FALSE;
        end if;
    end loop;
    return TRUE;
end;
$$;
select fn_check_sequence('ABCDE')


-- valid invalid pan categorization
create or replace view valid_view as (
with cte_cleaned_data as(
	select distinct upper(trim(pan_numbers)) as pan from pan
	where pan_numbers is not null 
	and trim (pan_numbers)<>''
), cte_valid_pan as(
	select * from cte_cleaned_data
	where fn_check_adjacent_repetition(pan) = 'false'
	and fn_check_sequence(substring(pan,1,5)) ='false'
	and fn_check_sequence(substring(pan,6,4)) = 'false'
	and pan ~ '^[A-Z]{5}[0-9]{4}[A-Z]$'
)
select c1.pan,
	case when c2.pan is null then 'Invalid'
	else 'Valid' end as validation
from cte_cleaned_data c1
left join cte_valid_pan c2 on c1.pan = c2.pan
)

select * from valid_view


-- REPORTS
with cte as(
select(select count(*) from pan) as no_of_records_processed,
	   count(*) filter(where vw.validation = 'Valid') no_of_valid_pans,
	   count(*) filter(where vw.validation = 'Invalid') no_of_invalid_pans
from valid_view vw
)

select no_of_records_processed, no_of_valid_pans,no_of_invalid_pans, 
	   no_of_records_processed - (no_of_valid_pans + no_of_invalid_pans) as missing_records
from cte
	   