create table if not exists
rdextra
(
    remessa uinteger,
    entidade varchar(4),
    conta_contabil varchar(24),
    especificacao varchar(148),
    orgao usmallint,
    nome_orgao varchar(80),
    uniorcam usmallint,
    nome_uniorcam varchar(80),
    valor decimal(11, 2),
    ingresso_dispendio char,
    identificador_dfc char,
    nome_identificador_dfc varchar(30),
    identificador_bf utinyint,
    nome_identificador_bf varchar(30),
    exercicio_recurso utinyint,
    nome_exercicio_recurso varchar(30),
    fonte_recurso usmallint,
    nome_fonte_recurso varchar(80)
);

delete from rdextra where remessa = {{remessa}};

insert into rdextra
(
    remessa,
    entidade,
    conta_contabil,
    orgao,
    uniorcam,
    valor,
    ingresso_dispendio,
    identificador_dfc,
    identificador_bf,
    exercicio_recurso,
    fonte_recurso
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
    round(cast(substring(raw_data, 52, 1) || ltrim(substring(raw_data, 25, 13), '0') as hugeint) / 100, 2),
    upper(substring(raw_data, 38, 1)),
    upper(substring(raw_data, 45, 1)),
    substring(raw_data, 46, 2),
    substring(raw_data, 48, 1),
    substring(raw_data, 49, 3)
from cache
where arquivo like 'rd_extra';

update rdextra
set entidade = case orgao
                   when 1 then 'cm'
                   when 12 then 'fpsm'
                   when 50 then 'fpsm'
                   else 'pm'
    end
where remessa = {{remessa}}
  and entidade is null or entidade like '';

update rdextra t
set
    especificacao = (select especificacao from pcasp where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and conta_contabil like t.conta_contabil limit 1),
    nome_orgao = (select nome from orgao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and orgao = t.orgao limit 1),
    nome_uniorcam = (select nome from uniorcam where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and uniorcam = t.uniorcam limit 1),
    nome_exercicio_recurso = (select nome from exercicio_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and exercicio_recurso = t.exercicio_recurso limit 1),
    nome_fonte_recurso = (select nome from fonte_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and fonte_recurso = t.fonte_recurso limit 1),
    nome_identificador_dfc = case identificador_dfc
                                when 'O' then 'Fluxo operacional'
                                when 'I' then 'Fluxo de investimento'
                                when 'F' then 'Fluxo de financiamento'
                                else null
                            end,
    nome_identificador_bf = case identificador_bf
                                when 1 then 'Transferências recebidas ou concedidas para execução orçamentária'
                                when 2 then 'Transferências financeiras recebidas ou concedidas independentes de execução orçamentária'
                                when 3 then 'Transferências recebidas ou concedidas para aporte de recursos para o RPPS'
                                when 4 then 'Resgate ou transferência de investimentos e aplicações financeiras'
                                when 5 then 'Bloqueio ou desbloqueio de caixa'
                                when 6 then 'Outros recebimentos ou pagamentos extraorçamentários'
                                when 7 then 'Depósitos restituíveis e valores vinculados'
                                else null
                            end
where nome_orgao is null or nome_orgao like '';
