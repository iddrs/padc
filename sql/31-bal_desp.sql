create table if not exists
baldesp
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
    elemento varchar(9),
    nome_elemento varchar(110),
    exercicio_recurso utinyint,
    nome_exercicio_recurso varchar(30),
    fonte_recurso usmallint,
    nome_fonte_recurso varchar(80),
    dotacao_inicial hugeint,
    atualizacao_monetaria hugeint,
    credito_suplementar hugeint,
    credito_especial hugeint,
    credito_extraordinario hugeint,
    reducao_dotacao hugeint,
    valor_empenhado hugeint,
    valor_liquidado hugeint,
    valor_pago hugeint,
    transferencia hugeint,
    transposicao hugeint,
    remanejamento hugeint,
    dotacao_atualizada hugeint,
    saldo_dotacao hugeint,
    valor_limitado hugeint,
    valor_recomposto hugeint,
    saldo_disponivel hugeint,
    empenhado_a_liquidar hugeint,
    empenhado_a_pagar hugeint,
    liquidado_a_pagar hugeint
);

delete from baldesp where remessa = {{remessa}};

insert into baldesp
(
    remessa,
    entidade,
    orgao,
    uniorcam,
    funcao,
    subfuncao,
    programa,
    projativ,
    elemento,
    dotacao_inicial,
    atualizacao_monetaria,
    credito_suplementar,
    credito_especial,
    credito_extraordinario,
    reducao_dotacao,
    valor_empenhado,
    valor_liquidado,
    valor_pago,
    valor_limitado,
    valor_recomposto,
    transferencia,
    transposicao,
    remanejamento,
    exercicio_recurso,
    fonte_recurso
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
    substring(raw_data, 26, 2),
    round(cast(substring(raw_data, 32, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 45, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 58, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 71, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 84, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 97, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 136, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 149, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 162, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 175, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 188, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 218, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 231, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 244, 13) as hugeint) / 100, 2),
    substring(raw_data, 257, 1),
    substring(raw_data, 258, 3),
from cache
where arquivo like 'bal_desp';

update baldesp
set
    entidade = case orgao
                   when 1 then 'cm'
                   when 12 then 'fpsm'
                   when 50 then 'fpsm'
                   else 'pm'
    end,
    dotacao_atualizada = dotacao_inicial
        + atualizacao_monetaria
        + credito_suplementar
        + credito_especial
        + credito_extraordinario
        - reducao_dotacao
        + transferencia
        + transposicao
        + remanejamento
where remessa = {{remessa}}
  and entidade is null or entidade like '';

update baldesp
set
    saldo_dotacao = dotacao_atualizada - valor_empenhado
where remessa = {{remessa}}
  and saldo_dotacao is null;

update baldesp
set
    saldo_disponivel = saldo_dotacao - valor_limitado + valor_recomposto,
    empenhado_a_liquidar = valor_empenhado - valor_liquidado,
    empenhado_a_pagar = valor_empenhado - valor_pago,
    liquidado_a_pagar = valor_liquidado - valor_pago
where remessa = {{remessa}}
  and saldo_disponivel is null;

update baldesp t
set
    nome_orgao = (select nome from orgao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and orgao = t.orgao limit 1),
    nome_uniorcam = (select nome from uniorcam where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and uniorcam = t.uniorcam limit 1),
    nome_elemento = (select especificacao from rubrica where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and rubrica like t.elemento || '.00.00.00.00' limit 1),
    nome_funcao = (select nome from funcao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and funcao = t.funcao limit 1),
    nome_subfuncao = (select nome from subfuncao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and subfuncao = t.subfuncao limit 1),
    nome_programa = (select nome from programa where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and programa = t.programa limit 1),
    nome_projativ = (select nome from projativ where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and projativ = t.projativ limit 1),
    nome_exercicio_recurso = (select nome from exercicio_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and exercicio_recurso = t.exercicio_recurso limit 1),
    nome_fonte_recurso = (select nome from fonte_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and fonte_recurso = t.fonte_recurso limit 1)
where nome_orgao is null or nome_orgao like '';
