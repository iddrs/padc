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
    especificacao_debito varchar(148),
    orgao_debito usmallint,
    nome_orgao_debito varchar(80),
    uniorcam_debito usmallint,
    nome_uniorcam_debito varchar(80),
    conta_contabil_credito varchar(24),
    especificacao_credito varchar(148),
    orgao_credito usmallint,
    nome_orgao_credito varchar(80),
    uniorcam_credito usmallint,
    nome_uniorcam_credito varchar(80),
    historico varchar(400),
    nr_liquidacao uhugeint,

    orgao usmallint,
    nome_orgao varchar(80),
    uniorcam usmallint,
    nome_uniorcam varchar(80),
    funcao usmallint,
    nome_funcao varchar(80),
    subfuncao usmallint,
    nome_subfuncao varchar(80),
    programa usmallint,
    nome_programa varchar(80),
    projativ usmallint,
    nome_projativ varchar(80),
    rubrica varchar(21),
    nome_rubrica varchar(110),
    ano_empenho usmallint,
    entidade_empenho utinyint,
    nr_empenho usmallint,
    credor uinteger,
    nome_credor varchar(60),
    caracteristica_peculiar usmallint,
    nome_caracteristica_peculiar varchar(30),
    registro_precos char,
    nr_licitacao uinteger,
    ano_licitacao usmallint,
    forma_contratacao varchar(3),
    nome_forma_contratacao varchar(30),
    base_legal utinyint,
    nome_base_legal varchar(30),
    despesa_funcionario char,
    nome_despesa_funcionario varchar(30),
    licitacao_compartilhada char,
    cnpj_gerenciador varchar(18),
    exercicio_recurso utinyint,
    nome_exercicio_recurso varchar(30),
    fonte_recurso usmallint,
    nome_fonte_recurso varchar(80),
    codigo_orcamentario usmallint,
    nome_codigo_orcamentario varchar(80),
    emenda_parlamentar usmallint,
    nome_emenda_parlamentar varchar(80)
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

update pagamento t
set
    especificacao_debito = (select especificacao from pcasp where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and conta_contabil like t.conta_contabil_debito limit 1),
    especificacao_credito = (select especificacao from pcasp where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and conta_contabil like t.conta_contabil_credito limit 1),
    nome_orgao_debito = (select nome from orgao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and orgao_debito = t.orgao limit 1),
    nome_uniorcam_debito = (select nome from uniorcam where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and uniorcam_debito = t.uniorcam limit 1),
    nome_orgao_credito = (select nome from orgao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and orgao_credito = t.orgao limit 1),
    nome_uniorcam_credito = (select nome from uniorcam where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and uniorcam_credito = t.uniorcam limit 1),
    nome_orgao = (select nome from orgao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and orgao = t.orgao limit 1),
    nome_uniorcam = (select nome from uniorcam where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and uniorcam = t.uniorcam limit 1),
    nome_funcao = (select nome from funcao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and funcao = t.funcao limit 1),
    nome_subfuncao = (select nome from subfuncao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and subfuncao = t.subfuncao limit 1),
    nome_programa = (select nome from programa where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and programa = t.programa limit 1),
    nome_projativ = (select nome from projativ where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and projativ = t.projativ limit 1),
    nome_rubrica = (select especificacao from rubrica where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and rubrica like t.rubrica limit 1),
    nome_credor = (select nome from credor where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and credor = t.credor limit 1),
    nome_caracteristica_peculiar = (select nome from caracteristica_peculiar where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and caracteristica_peculiar = t.caracteristica_peculiar limit 1),
    nome_forma_contratacao = (select nome from forma_contratacao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and forma_contratacao like t.forma_contratacao limit 1),
    nome_base_legal = (select nome from base_legal where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and base_legal = t.base_legal limit 1),
    nome_despesa_funcionario = (select nome from despesa_funcionario where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and despesa_funcionario like t.despesa_funcionario limit 1),
    nome_exercicio_recurso = (select nome from exercicio_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and exercicio_recurso = t.exercicio_recurso limit 1),
    nome_fonte_recurso = (select nome from fonte_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and fonte_recurso = t.fonte_recurso limit 1),
    nome_codigo_orcamentario = (select nome from codigo_orcamentario where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and codigo_orcamentario = t.codigo_orcamentario limit 1),
    nome_emenda_parlamentar = (select nome from emenda_parlamentar where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and emenda_parlamentar = t.emenda_parlamentar limit 1)
where nome_orgao is null or nome_orgao like '';
