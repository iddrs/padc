create table if not exists
empenho
(
    remessa uinteger,
    entidade varchar(4),
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
    chave_empenho varchar(13),
    ano_empenho usmallint,
    entidade_empenho utinyint,
    nr_empenho usmallint,
    data date,
    valor decimal(11, 2),
    credor uinteger,
    nome_credor varchar(60),
    caracteristica_peculiar usmallint,
    nome_caracteristica_peculiar varchar(30),
    registro_precos char,
    nr_licitacao uinteger,
    ano_licitacao usmallint,
    historico varchar(400),
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

delete from empenho where remessa = {{remessa}};

insert into empenho
(
    remessa,
    entidade,
    orgao,
    uniorcam,
    funcao,
    subfuncao,
    programa,
    projativ,
    rubrica,
    chave_empenho,
    ano_empenho,
    entidade_empenho,
    nr_empenho,
    data,
    valor,
    credor,
    caracteristica_peculiar,
    registro_precos,
    nr_licitacao,
    ano_licitacao,
    historico,
    forma_contratacao,
    base_legal,
    despesa_funcionario,
    licitacao_compartilhada,
    cnpj_gerenciador,
    exercicio_recurso,
    fonte_recurso,
    codigo_orcamentario,
    emenda_parlamentar
)
select
    remessa,
    entidade,
    substring(raw_data, 1, 2),
    substring(raw_data, 1, 4),
    substring(raw_data, 5, 2),
    substring(raw_data, 7, 3),
    substring(raw_data, 10, 4),
    substring(raw_data, 17, 5),
    substring(raw_data, 22, 1) || '.' ||
    substring(raw_data, 23, 1) || '.' ||
    substring(raw_data, 24, 2) || '.' ||
    substring(raw_data, 26, 2) || '.' ||
    substring(raw_data, 28, 2) || '.' ||
    substring(raw_data, 30, 2) || '.' ||
    substring(raw_data, 32, 2) || '.' ||
    substring(raw_data, 34, 2),
    substring(raw_data, 45, 13),
    substring(raw_data, 45, 5),
    substring(raw_data, 50,2),
    substring(raw_data, 52, 5),
    make_date(cast(substring(raw_data, 62, 4) as usmallint), cast(substring(raw_data, 60, 2) as utinyint), cast(substring(raw_data, 58, 2) as utinyint)),
    round(cast(substring(raw_data, 79, 1) || ltrim(substring(raw_data, 66, 13), '0') as hugeint) / 100, 2),
    substring(raw_data, 80, 10),
    substring(raw_data, 255, 3),
    upper(substring(raw_data, 260, 1)),
    substring(raw_data, 281, 20),
    substring(raw_data, 301, 4),
    trim(substring(raw_data, 305, 400)),
    upper(substring(raw_data, 705, 3)),
    substring(raw_data, 708, 2),
    upper(substring(raw_data, 710, 1)),
    upper(substring(raw_data, 711, 1)),
    substring(raw_data, 712, 2) || '.' ||
    substring(raw_data, 714, 3) || '.' ||
    substring(raw_data, 717, 3) || '/' ||
    substring(raw_data, 720, 4) || '-' ||
    substring(raw_data, 724, 2),
    substring(raw_data, 730, 1),
    substring(raw_data, 731, 3),
    substring(raw_data, 734, 4),
    substring(raw_data, 738, 4)
from cache
where arquivo like 'empenho';

update empenho
set entidade = case orgao
                   when 1 then 'cm'
                   when 12 then 'fpsm'
                   when 50 then 'fpsm'
                   else 'pm'
    end
where remessa = {{remessa}}
  and entidade is null or entidade like '';

update empenho t
set
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
