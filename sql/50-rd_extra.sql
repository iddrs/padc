create table if not exists
rdextra
(
    remessa uinteger,
    entidade varchar(4),
    conta_contabil varchar(24),
    orgao usmallint,
    uniorcam usmallint,
    valor decimal(11, 2),
    ingresso_dispendio char,
    identificador_dfc char,
    identificador_bf utinyint,
    exercicio_recurso utinyint,
    fonte_recurso usmallint
);

delete from rdextra where remessa = {{remessa}};

insert into rdextra
(
    remessa,
    entidade,
    conta_contabil,
    orgao,
    uniorcam,
    valor,
    ingresso_dispendio,
    identificador_dfc,
    identificador_bf,
    exercicio_recurso,
    fonte_recurso
)
select
    remessa,
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
    round(cast(substring(raw_data, 52, 1) || ltrim(substring(raw_data, 25, 13), '0') as hugeint) / 100, 2),
    upper(substring(raw_data, 38, 1)),
    upper(substring(raw_data, 45, 1)),
    substring(raw_data, 46, 2),
    substring(raw_data, 48, 1),
    substring(raw_data, 49, 3)
from cache
where arquivo like 'rd_extra';

update rdextra
set entidade = case orgao
                   when 1 then 'cm'
                   when 12 then 'fpsm'
                   when 50 then 'fpsm'
                   else 'pm'
    end
where remessa = {{remessa}}
  and entidade is null or entidade like '';
