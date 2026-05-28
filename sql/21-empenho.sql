create table if not exists
empenho
(
    remessa uinteger,
    entidade varchar(4),
    orgao usmallint,
    uniorcam usmallint,
    funcao usmallint,
    subfuncao usmallint,
    programa usmallint,
    projativ usmallint,
    rubrica varchar(21),
    chave_empenho varchar(13),
    ano_empenho usmallint,
    entidade_empenho utinyint,
    nr_empenho usmallint,
    data date,
    valor decimal(11, 2),
    credor uinteger,
    caracteristica_peculiar usmallint,
    registro_precos char,
    nr_licitacao uinteger,
    ano_licitacao usmallint,
    historico varchar(400),
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