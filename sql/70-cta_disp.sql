create table if not exists
ctadisp
(
    exercicio usmallint,
    entidade varchar(4),
    conta_contabil varchar(24),
    orgao usmallint,
    uniorcam usmallint,
    banco uinteger,
    agencia varchar(5),
    conta_corrente varchar(20),
    tipo_conta utinyint,
    classificacao utinyint,
    exercicio_recurso utinyint,
    fonte_recurso usmallint,
    codigo_orcamentario usmallint,
    emenda_parlamentar usmallint
);

insert into ctadisp
(
    exercicio,
    entidade,
    conta_contabil,
    orgao,
    uniorcam,
    banco,
    agencia,
    conta_corrente,
    tipo_conta,
    classificacao,
    exercicio_recurso,
    fonte_recurso,
    codigo_orcamentario,
    emenda_parlamentar
)
select
    cast(substring(cast(remessa as varchar(6)), 1, 4) as usmallint),
    entidade,
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 1, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 2, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 3, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 4, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 5, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 6, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 8, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 10, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 12, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 14, 2),
    substring(raw_data, 21, 2),
    substring(raw_data, 21, 4),
    substring(raw_data, 29, 5),
    trim(substring(raw_data, 34, 5)),
    trim(substring(raw_data, 39, 20)),
    substring(raw_data, 59, 1),
    substring(raw_data, 60, 1),
    substring(raw_data, 65, 1),
    substring(raw_data, 66, 3),
    substring(raw_data, 69, 4),
    substring(raw_data, 73, 4)
from cache
where arquivo like 'cta_disp';

CREATE TABLE ctadisp_temp AS
SELECT DISTINCT * FROM ctadisp;

DROP TABLE ctadisp;

ALTER TABLE ctadisp_temp RENAME TO ctadisp;