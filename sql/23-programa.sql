create table if not exists
programa
(
    exercicio usmallint,
    programa usmallint,
    nome varchar(80)
);

insert into programa
(
    exercicio,
    programa,
    nome
)
select
    substring(raw_data, 1, 4),
    substring(raw_data, 5, 4),
    trim(substring(raw_data, 9, 80))
from cache
where arquivo like 'programa';

CREATE TABLE programa_temp AS
SELECT DISTINCT * FROM programa;

DROP TABLE programa;

ALTER TABLE programa_temp RENAME TO programa;