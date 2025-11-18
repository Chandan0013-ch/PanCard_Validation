create table pan(
pan_numbers text
)

select * from pan

--CLEANING PROCESS

--Identify and handle missing data

select * from pan 
where pan_numbers is null--965

--Check for duplicates
select pan_numbers,count(*) from pan
where pan_numbers is not null
group by 1
having count(*)>1--05

--Handle leading/trailing spaces
select pan_numbers
from pan
where pan_numbers<>trim(pan_numbers)--09

--Correct letter case
select * 
from pan
where pan_numbers<>upper(pan_numbers)--990


select distinct upper(trim(pan_numbers))
from pan
where pan_numbers is not null and trim(pan_numbers)<>''--9025
--cleaning process is done here


--VALIDATION PROCESS

-- function to check adjacent characters are repitative so 
-- it should return true if adjacent character are adjacent 
-- else return false

create or replace function check_adjacent(p text)
returns boolean
language plpgsql
as $$
begin
for i in 1 .. (length(p) -1)    
loop
if substring(p, i,1)=substring(p, i+1,1)
then
return true;
end if;
end loop;
return false;
end;
 $$
   
 select * from check_adjacent('AABCD')

 -- Function to check if characters are sequencial such as ABCDE, LMNOP, XYZ etc. 
-- Returns true if characters are sequencial else returns false

create or replace function check_sequence(p text)
returns boolean
language plpgsql
as $$
declare i int;
begin
for i in 1..(length(p)-1)
loop
if ASCII(substring(p from i + 1 for 1))-ASCII(substring(p from i for 1))<> 1
then 
return false;
end if;
end loop;
return true;
end;
$$

select * from check_sequence('ABCDE')


-- CATEGARIZATION  THE VALID AND INVALID

create or replace view valid_Invalid_pan as(
with cleaned_data as(
select distinct upper(trim(pan_numbers)) as pan
from pan
where pan_numbers is not null and trim(pan_numbers)<>''
),validate_data as(
select * from cleaned_data
where check_adjacent(pan) = 'false'
and  check_sequence (substring(pan,1,5))='false'
and check_sequence(substring(pan,6,4))='false'
and pan ~ '^[A-Z]{5}[0-9]{4}[A-Z]$'
)
select cd.pan,
case when vd.pan is null then 'Invalid'
 else 'Valid' end as validate_pan
from cleaned_data cd
left join validate_data vd
on cd.pan=vd.pan
)

select * from valid_Invalid_pan

with cte as(
select(select count(*) from pan) as no_of_records_processed,
	   count(*) filter(where vip.validate_pan = 'Valid') no_of_valid_pans,
	   count(*) filter(where vip.validate_pan = 'Invalid') no_of_invalid_pans
from valid_Invalid_pan vip
)
select no_of_records_processed, no_of_valid_pans,no_of_invalid_pans, 
	   no_of_records_processed - (no_of_valid_pans + no_of_invalid_pans) as missing_records
from cte
   



