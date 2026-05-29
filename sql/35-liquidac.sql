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
    nome_tipo_contrato varchar(30),

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

update liquidacao t
set
    nome_tipo_contrato = (select nome from tipo_contrato where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and tipo_contrato like t.tipo_contrato limit 1),
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
