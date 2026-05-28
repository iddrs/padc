create table if not exists
baldesp
(
    remessa uinteger,
    entidade varchar(4),
    orgao usmallint,
    uniorcam usmallint,
    funcao usmallint,
    subfuncao usmallint,
    programa usmallint,
    projativ usmallint,
    elemento varchar(9),
    dotacao_inicial hugeint,
    atualizacao_monetaria hugeint,
    credito_suplementar hugeint,
    credito_especial hugeint,
    credito_extraordinario hugeint,
    reducao_dotacao hugeint,
    valor_empenhado hugeint,
    valor_liquidado hugeint,
    valor_pago hugeint,
    valor_limitado hugeint,
    valor_recomposto hugeint,
    transferencia hugeint,
    transposicao hugeint,
    remanejamento hugeint,
    exercicio_recurso utinyint,
    fonte_recurso usmallint,
    dotacao_atualizada hugeint,
    saldo_dotacao hugeint,
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