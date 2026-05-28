create table if not exists
projativ
(
    exercicio usmallint,
    projativ usmallint,
    nome varchar(80),
    identificador utinyint
);

insert into projativ
(
    exercicio,
    projativ,
    nome,
    identificador
)
select
    substring(raw_data, 1, 4),
    substring(raw_data, 5, 5),
    trim(substring(raw_data, 10, 80)),
    substring(raw_data, 90, 2)
from cache
where arquivo like 'projativ';

CREATE TABLE projativ_temp AS
SELECT DISTINCT * FROM projativ;

DROP TABLE projativ;

ALTER TABLE projativ_temp RENAME TO projativ;