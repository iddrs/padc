create table if not exists
liquidacao
(
    remessa uinteger,
    entidade varchar(4),
    chave_empenho varchar(13),
    nr_liquidacao uhugeint,
    data date,
    valor decimal(11, 2),
    operacao uhugeint,
    historico varchar(400),
    existe_contrato char,
    nr_contrato_tce uinteger,
    nr_contrato varchar(20),
    ano_contrato usmallint,
    existe_nota_fiscal char,
    nr_nota_fiscal uhugeint,
    serie_nota_fiscal varchar(3),
    tipo_contrato char,

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

delete from liquidacao where remessa = {{remessa}};

insert into liquidacao
(
    remessa,
    chave_empenho,
    nr_liquidacao,
    data,
    valor,
    operacao,
    historico,
    existe_contrato,
    nr_contrato_tce,
    nr_contrato,
    ano_contrato,
    existe_nota_fiscal,
    nr_nota_fiscal,
    serie_nota_fiscal,
    tipo_contrato
)
select
    remessa,
    substring(raw_data, 1, 13),
    substring(raw_data, 14, 20),
    make_date(cast(substring(raw_data, 38, 4) as usmallint), cast(substring(raw_data, 36, 2) as utinyint), cast(substring(raw_data, 34, 2) as utinyint)),
    round(cast(substring(raw_data, 55, 1) || ltrim(substring(raw_data, 42, 13), '0') as hugeint) / 100, 2),
    substring(raw_data, 221, 30),
    trim(substring(raw_data, 251, 400)),
    upper(substring(raw_data, 651, 1)),
    substring(raw_data, 652, 20),
    trim(substring(raw_data, 672, 20)),
    substring(raw_data, 692, 4),
    upper(substring(raw_data, 696, 1)),
    substring(raw_data, 697, 9),
    trim(substring(raw_data, 706, 3)),
    upper(substring(raw_data, 709, 1))
from cache
where arquivo like 'liquidac';

update liquidacao d
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

update liquidacao
set entidade = case orgao
                   when 1 then 'cm'
                   when 12 then 'fpsm'
                   when 50 then 'fpsm'
                   else 'pm'
    end
where remessa = {{remessa}}
  and entidade is null or entidade like '';