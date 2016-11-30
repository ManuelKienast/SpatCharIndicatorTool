select *
from rentbln11
limit 1;

select qmmiete, wohnflaech, ausstattun, mietekalt
from rentbln11
order by qmmiete desc;

select qmmiete, einstellda, laufzeitta, einstellda + laufzeitta::integer as expectedNewEinst
from rentbln11
where qmmiete::text LIKE ('16.9014%')
ORDER BY einstellda