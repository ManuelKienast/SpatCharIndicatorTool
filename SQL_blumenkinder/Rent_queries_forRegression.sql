select sum(coalesce(green_tvz_surround,0)), tvz_id
from rent
where green_tvz_surround isnull
group by tvz_id

select * 
from rent
where tvz_id=722

SELECT column_name, data_type
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_NAME = 'rent'
      AND data_type = 'text'
      ;

select case 
WHEN a.gbgroesse = 1 THEN 1 
ELSE 0 END 
from rent as a

select count(id)
from rent
where gbgroesse = 1

alter table rent drop column zuimmeranza

select zimmeranza, zimmeranza_num
from rent
where zimmeranza::numeric != zimmeranza_num
limit 1000;