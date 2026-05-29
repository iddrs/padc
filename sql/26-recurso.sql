create table if not exists
fonte_recurso
(
    exercicio usmallint,
    exercicio_recurso utinyint,
    fonte_recurso usmallint,
    nome varchar(80),
    finalidade varchar(160)
);

insert into fonte_recurso
(
    exercicio,
    exercicio_recurso,
    fonte_recurso,
    nome,
    finalidade
)
select
    cast(substring(cast(remessa as varchar(6)), 1, 4) as usmallint),
    substring(raw_data, 1, 1),
    substring(raw_data, 2, 3),
    trim(substring(raw_data, 5, 80)),
    trim(substring(raw_data, 85, 160))
from cache
where arquivo like 'recurso';

CREATE TABLE fonte_recurso_temp AS
SELECT DISTINCT * FROM fonte_recurso;

DROP TABLE fonte_recurso;

ALTER TABLE fonte_recurso_temp RENAME TO fonte_recurso;