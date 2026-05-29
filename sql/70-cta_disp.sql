create table if not exists
ctadisp
(
    exercicio usmallint,
    entidade varchar(4),
    conta_contabil varchar(24),
    especificacao varchar(148),
    orgao usmallint,
    nome_orgao varchar(80),
    uniorcam usmallint,
    nome_uniorcam varchar(80),
    banco uinteger,
    agencia varchar(5),
    conta_corrente varchar(20),
    tipo_conta utinyint,
    nome_tipo_conta varchar(30),
    classificacao utinyint,
    nome_classificacao varchar(30),
    exercicio_recurso utinyint,
    nome_exercicio_recurso varchar(30),
    fonte_recurso usmallint,
    nome_fonte_recurso varchar(80),
    codigo_orcamentario usmallint,
    nome_codigo_orcamentario varchar(80),
    emenda_parlamentar usmallint,
    nome_emenda_parlamentar varchar(80),
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

update ctadisp
set entidade = case orgao
                   when 1 then 'cm'
                   when 12 then 'fpsm'
                   when 50 then 'fpsm'
                   else 'pm'
    end
where exercicio = {{exercicio}}
  and entidade is null or entidade like '';

CREATE TABLE ctadisp_temp AS
SELECT DISTINCT * FROM ctadisp;

DROP TABLE ctadisp;

ALTER TABLE ctadisp_temp RENAME TO ctadisp;

update ctadisp t
set
    especificacao = (select especificacao from pcasp where exercicio = t.exercicio and conta_contabil like t.conta_contabil limit 1),
    nome_orgao = (select nome from orgao where exercicio = t.exercicio and orgao = t.orgao limit 1),
    nome_uniorcam = (select nome from uniorcam where exercicio = t.exercicio and uniorcam = t.uniorcam limit 1),
    nome_exercicio_recurso = (select nome from exercicio_recurso where exercicio = t.exercicio and exercicio_recurso = t.exercicio_recurso limit 1),
    nome_fonte_recurso = (select nome from fonte_recurso where exercicio = t.exercicio and fonte_recurso = t.fonte_recurso limit 1),
    nome_codigo_orcamentario = (select nome from codigo_orcamentario where exercicio = t.exercicio and codigo_orcamentario = t.codigo_orcamentario limit 1),
    nome_emenda_parlamentar = (select nome from emenda_parlamentar where exercicio = t.exercicio and emenda_parlamentar = t.emenda_parlamentar limit 1),
    nome_tipo_conta = case tipo_conta
    when 1 then 'Caixa'
    when 2 then 'Banco conta-movimento'
    when 3 then 'Banco conta-aplicação'
    when 4 then 'Depósito de sentenças judiciais'
    when 5 then 'Depósitos judiciais de restos a pagar'
    else null
end,
    nome_classificacao = case classificacao
                            when 1 then 'Executivo'
                            when 2 then 'Legislativo'
                            when 3 then 'RPPS'
                            when 9 then 'Outros'
                            else null
end
where nome_orgao is null or nome_orgao like '';