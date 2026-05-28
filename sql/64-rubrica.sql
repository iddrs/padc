create table if not exists
rubrica
(
    exercicio usmallint,
    rubrica varchar(21),
    especificacao varchar(110),
    tipo_nivel char,
    nivel utinyint
);

insert into rubrica
(
    exercicio,
    rubrica,
     especificacao,
     tipo_nivel,
     nivel
)
select
    substring(raw_data, 1, 4),
    substring(raw_data, 5, 1) || '.' ||
    substring(raw_data, 6, 1) || '.' ||
    substring(raw_data, 7, 2) || '.' ||
    substring(raw_data, 9, 2) || '.' ||
    substring(raw_data, 11, 2) || '.' ||
    substring(raw_data, 13, 2) || '.' ||
    substring(raw_data, 15, 2) || '.' ||
    substring(raw_data, 17, 2),
    trim(substring(raw_data, 20, 110)),
    upper(substring(raw_data, 130, 1)),
    substring(raw_data, 131, 2)
from cache
where arquivo like 'rubrica';

CREATE TABLE rubrica_temp AS
SELECT DISTINCT * FROM rubrica;

DROP TABLE rubrica;

ALTER TABLE rubrica_temp RENAME TO rubrica;