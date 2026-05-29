create table if not exists
uniorcam
(
    exercicio usmallint,
    orgao utinyint,
    uniorcam usmallint,
    nome varchar(80),
    identificador utinyint,
    cnpj varchar(18)
);

insert into uniorcam
(
    exercicio,
    orgao,
    uniorcam,
    nome,
    identificador,
    cnpj
)
select
    substring(raw_data, 1, 4),
    substring(raw_data, 5, 2),
    substring(raw_data, 5, 4),
    trim(substring(raw_data, 9, 80)),
substring(raw_data, 89, 2),
    substring(raw_data, 91, 2) || '.' ||
    substring(raw_data, 93, 3) || '.' ||
    substring(raw_data, 96, 3) || '/' ||
    substring(raw_data, 99, 4) || '-' ||
    substring(raw_data, 103, 2)
from cache
where arquivo like 'uniorcam';

CREATE TABLE uniorcam_temp AS
SELECT DISTINCT * FROM uniorcam;

DROP TABLE uniorcam;

ALTER TABLE uniorcam_temp RENAME TO uniorcam;