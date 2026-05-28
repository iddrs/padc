create table if not exists
orgao
(
    exercicio usmallint,
    orgao utinyint,
    nome varchar(80)
);

insert into orgao
(
    exercicio,
    orgao,
    nome
)
select
    substring(raw_data, 1, 4),
    substring(raw_data, 5, 2),
    trim(substring(raw_data, 7, 80))
from cache
where arquivo like 'orgao';

CREATE TABLE decreto_temp AS
SELECT DISTINCT * FROM decreto;

DROP TABLE decreto;

ALTER TABLE decreto_temp RENAME TO decreto;