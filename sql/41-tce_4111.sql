create table if not exists
diario
(
    remessa uinteger,
    entidade varchar(4),
    conta_contabil varchar(24),
    orgao usmallint,
    uniorcam usmallint,
    nr_lancamento uhugeint,
    nr_lote uhugeint,
    nr_documento uhugeint,
    data date,
    valor decimal(11, 2),
    tipo_lancamento char,
    nr_arquivamento uhugeint,
    historico varchar(150),
    tipo_documento utinyint,
    natureza_informacao char,
    indicador_superavit char,
    exercicio_recurso utinyint,
    fonte_recurso usmallint,
    codigo_orcamentario usmallint,
    emenda_parlamentar usmallint
);

delete from diario where remessa = {{remessa}};

insert into diario
(
    remessa,
    entidade,
    conta_contabil,
    orgao,
    uniorcam,
    nr_lancamento,
    nr_lote,
    nr_documento,
    data,
    valor,
    tipo_lancamento,
    nr_arquivamento,
    historico,
    tipo_documento,
    natureza_informacao,
    indicador_superavit,
    exercicio_recurso,
    fonte_recurso,
    codigo_orcamentario,
    emenda_parlamentar
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
    substring(raw_data, 29, 12),
    substring(raw_data, 41, 12),
    substring(raw_data, 53, 13),
    make_date(cast(substring(raw_data, 70, 4) as usmallint), cast(substring(raw_data, 68, 2) as utinyint), cast(substring(raw_data, 66, 2) as utinyint)),
    round(cast(substring(raw_data, 74, 17) as hugeint) / 100, 2),
    upper(substring(raw_data, 91, 1)),
    substring(raw_data, 92, 12),
    trim(substring(raw_data, 104, 150)),
    substring(raw_data, 254, 1),
    upper(substring(raw_data, 255, 1)),
    upper(substring(raw_data, 256, 1)),
    substring(raw_data, 265, 1),
    substring(raw_data, 266, 3),
    substring(raw_data, 269, 4),
    substring(raw_data, 273, 4)
from cache
where arquivo like 'tce_4111';

update diario
set entidade = case orgao
                   when 1 then 'cm'
                   when 12 then 'fpsm'
                   when 50 then 'fpsm'
                   else 'pm'
    end
where remessa = {{remessa}}
  and entidade is null or entidade like '';