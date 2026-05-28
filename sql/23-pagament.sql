create table if not exists
pagamento
(
    remessa uinteger,
    entidade varchar(4),
    chave_empenho varchar(13),
    nr_pagamento uhugeint,
    data date,
    valor decimal(11, 2),
    operacao varchar(30),
    conta_contabil_debito varchar(24),
    orgao_debito usmallint,
    uniorcam_debito usmallint,
    conta_contabil_credito varchar(24),
    orgao_credito usmallint,
    uniorcam_credito usmallint,
    historico varchar(400),
    nr_liquidacao uhugeint,

    orgao usmallint,
    uniorcam usmallint,
    funcao usmallint,
    subfuncao usmallint,
    programa usmallint,
    projativ usmallint,
    rubrica varchar(21),
    ano_empenho usmallint,
    entidade_empenho utinyint,
    nr_empenho usmallint,
    credor uinteger,
    caracteristica_peculiar usmallint,
    registro_precos char,
    nr_licitacao uinteger,
    ano_licitacao usmallint,
    forma_contratacao varchar(3),
    base_legal utinyint,
    despesa_funcionario char,
    licitacao_compartilhada char,
    cnpj_gerenciador varchar(18),
    exercicio_recurso utinyint,
    fonte_recurso usmallint,
    codigo_orcamentario usmallint,
    emenda_parlamentar usmallint
);

delete from pagamento where remessa = {{remessa}};

insert into pagamento
(
    remessa,
    chave_empenho,
    nr_pagamento,
    data,
    valor,
    operacao,
    conta_contabil_debito,
    orgao_debito,
    uniorcam_debito,
    conta_contabil_credito,
    orgao_credito,
    uniorcam_credito,
    historico,
    nr_liquidacao
)
select
    remessa,
    substring(raw_data, 1, 13),
    substring(raw_data, 14, 20),
    make_date(cast(substring(raw_data, 38, 4) as usmallint), cast(substring(raw_data, 36, 2) as utinyint), cast(substring(raw_data, 34, 2) as utinyint)),
    round(cast(substring(raw_data, 55, 1) || ltrim(substring(raw_data, 42, 13), '0') as hugeint) / 100, 2),
    substring(raw_data, 176, 30),
    substring(rpad(ltrim(substring(raw_data, 206, 20), '0'), 20, '0'), 1, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 206, 20), '0'), 20, '0'), 2, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 206, 20), '0'), 20, '0'), 3, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 206, 20), '0'), 20, '0'), 4, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 206, 20), '0'), 20, '0'), 5, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 206, 20), '0'), 20, '0'), 6, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 206, 20), '0'), 20, '0'), 8, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 206, 20), '0'), 20, '0'), 10, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 206, 20), '0'), 20, '0'), 12, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 206, 20), '0'), 20, '0'), 14, 2),
    substring(raw_data, 226, 2),
    substring(raw_data, 226, 4),

    substring(rpad(ltrim(substring(raw_data, 230, 20), '0'), 20, '0'), 1, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 230, 20), '0'), 20, '0'), 2, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 230, 20), '0'), 20, '0'), 3, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 230, 20), '0'), 20, '0'), 4, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 230, 20), '0'), 20, '0'), 5, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 230, 20), '0'), 20, '0'), 6, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 230, 20), '0'), 20, '0'), 8, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 230, 20), '0'), 20, '0'), 10, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 230, 20), '0'), 20, '0'), 12, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 230, 20), '0'), 20, '0'), 14, 2),
    substring(raw_data, 250, 2),
    substring(raw_data, 250, 4),
    trim(substring(raw_data, 254, 400)),
    substring(raw_data, 654, 20)
from cache
where arquivo like 'pagament';

update pagamento d
set
    entidade = o.entidade,
    orgao = o.orgao,
    uniorcam  = o.uniorcam,
    funcao  = o.funcao,
    subfuncao  = o.subfuncao,
    programa  = o.programa,
    projativ  = o.projativ,
    rubrica  = o.rubrica,
    ano_empenho  = o.ano_empenho,
    entidade_empenho  = o.entidade_empenho,
    nr_empenho  = o.nr_empenho,
    credor  = o.credor,
    caracteristica_peculiar  = o.caracteristica_peculiar,
    registro_precos  = o.registro_precos,
    nr_licitacao  = o.nr_licitacao,
    ano_licitacao  = o.ano_licitacao,
    forma_contratacao  = o.forma_contratacao,
    base_legal  = o.base_legal,
    despesa_funcionario  = o.despesa_funcionario,
    licitacao_compartilhada  = o.licitacao_compartilhada,
    cnpj_gerenciador  = o.cnpj_gerenciador,
    exercicio_recurso  = o.exercicio_recurso,
    fonte_recurso  = o.fonte_recurso,
    codigo_orcamentario = o.codigo_orcamentario,
    emenda_parlamentar  = o.emenda_parlamentar
from empenho o
where o.remessa = d.remessa
    and o.chave_empenho = d.chave_empenho;

update pagamento
set entidade = case orgao
                   when 1 then 'cm'
                   when 12 then 'fpsm'
                   when 50 then 'fpsm'
                   else 'pm'
    end
where remessa = {{remessa}}
  and entidade is null or entidade like '';