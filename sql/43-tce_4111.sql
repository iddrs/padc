create table if not exists
diario
(
    remessa uinteger,
    entidade varchar(4),
    conta_contabil varchar(24),
    especificacao varchar(148),
    orgao usmallint,
    nome_orgao varchar(80),
    uniorcam usmallint,
    nome_uniorcam varchar(80),
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
    nome_natureza_informacao varchar(30),
    indicador_superavit char,
    nome_indicador_superavit varchar(30),
    exercicio_recurso utinyint,
    nome_exercicio_recurso varchar(30),
    fonte_recurso usmallint,
    nome_fonte_recurso varchar(80),
    codigo_orcamentario usmallint,
    nome_codigo_orcamentario varchar(80),
    emenda_parlamentar usmallint,
    nome_emenda_parlamentar varchar(80)
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

update diario t
set
    especificacao = (select especificacao from pcasp where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and conta_contabil like t.conta_contabil limit 1),
    nome_orgao = (select nome from orgao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and orgao = t.orgao limit 1),
    nome_uniorcam = (select nome from uniorcam where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and uniorcam = t.uniorcam limit 1),
    nome_exercicio_recurso = (select nome from exercicio_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and exercicio_recurso = t.exercicio_recurso limit 1),
    nome_fonte_recurso = (select nome from fonte_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and fonte_recurso = t.fonte_recurso limit 1),
    nome_codigo_orcamentario = (select nome from codigo_orcamentario where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and codigo_orcamentario = t.codigo_orcamentario limit 1),
    nome_emenda_parlamentar = (select nome from emenda_parlamentar where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and emenda_parlamentar = t.emenda_parlamentar limit 1),
    nome_natureza_informacao = case natureza_informacao when 'P' then 'Patrimonial' when 'O' then 'Orçamentária' when 'C' then 'Controle' else null end,
    nome_indicador_superavit = case indicador_superavit when 'F' then 'Financeiro' when 'P' then 'Permanente' else null end
where nome_orgao is null or nome_orgao like '';
