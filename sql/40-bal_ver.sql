create table if not exists
balver
(
    remessa uinteger,
    entidade varchar(4),
    conta_contabil varchar(24),
    orgao usmallint,
    uniorcam usmallint,
    saldo_anterior_devedor decimal(11, 2),
    saldo_anterior_credor decimal(11, 2),
    saldo_anterior decimal(11, 2),
    natureza_saldo_anterior char,
    movimento_debito decimal(11, 2),
    movimento_credito decimal(11, 2),
    saldo_atual_devedor decimal(11, 2),
    saldo_atual_credor decimal(11, 2),
    saldo_atual decimal(11, 2),
    natureza_saldo_atual char,
    especificacao varchar(148),
    tipo_nivel char,
    nivel usmallint,
    escrituracao char,
    natureza_informacao char,
    indicador_superavit char,
    exercicio_recurso utinyint,
    fonte_recurso usmallint,
    codigo_orcamentario usmallint,
    emenda_parlamentar usmallint
);

delete from balver where remessa = {{remessa}};

insert into balver
(
    remessa,
    entidade,
    conta_contabil,
    orgao,
    uniorcam,
    saldo_anterior_devedor,
    saldo_anterior_credor,
    movimento_debito,
    movimento_credito,
    saldo_atual_devedor,
    saldo_atual_credor,
    especificacao,
    tipo_nivel,
    nivel,
    escrituracao,
    natureza_informacao,
    indicador_superavit,
    exercicio_recurso,
    fonte_recurso,
    codigo_orcamentario,
    emenda_parlamentar
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
    round(cast(substring(raw_data, 25, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 38, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 51, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 64, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 77, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 90, 13) as hugeint) / 100, 2),
    trim(substring(raw_data, 103, 148)),
    upper(substring(raw_data, 251, 1)),
    substring(raw_data, 252, 2),
    upper(substring(raw_data, 255, 1)),
    upper(substring(raw_data, 256, 1)),
    upper(substring(raw_data, 257, 1)),
    substring(raw_data, 266, 1),
    substring(raw_data, 267, 3),
    substring(raw_data, 270, 4),
    substring(raw_data, 274, 4)
from cache
where arquivo like 'bal_ver';

update balver
set entidade = case orgao
                   when 1 then 'cm'
                   when 12 then 'fpsm'
                   when 50 then 'fpsm'
                   else 'pm'
    end
where remessa = {{remessa}}
  and entidade is null or entidade like '';

update balver
set
    saldo_anterior = case
        when substring(conta_contabil, 1, 1) in ('1', '3', '5', '7') then saldo_anterior_devedor - saldo_anterior_credor
        when substring(conta_contabil, 1, 1) in ('2', '4', '6', '8') then saldo_anterior_credor - saldo_anterior_devedor
        else 0.0
    end,
    saldo_atual = case
                      when substring(conta_contabil, 1, 1) in ('1', '3', '5', '7') then saldo_atual_devedor - saldo_atual_credor
                      when substring(conta_contabil, 1, 1) in ('2', '4', '6', '8') then saldo_atual_credor - saldo_atual_devedor
                      else 0.0
        end
where  remessa = {{remessa}}
    and saldo_anterior is null;

update balver
set
    natureza_saldo_anterior = case
        when substring(conta_contabil, 1, 1) in ('1', '3', '5', '7') and saldo_anterior > 0 then 'D'
        when substring(conta_contabil, 1, 1) in ('1', '3', '5', '7') and saldo_anterior < 0 then 'C'
        when substring(conta_contabil, 1, 1) in ('2', '4', '6', '8') and saldo_anterior > 0 then 'C'
        when substring(conta_contabil, 1, 1) in ('2', '4', '6', '8') and saldo_anterior < 0 then 'D'
        else ''
    end,
    natureza_saldo_atual = case
      when substring(conta_contabil, 1, 1) in ('1', '3', '5', '7') and saldo_atual > 0 then 'D'
      when substring(conta_contabil, 1, 1) in ('1', '3', '5', '7') and saldo_atual < 0 then 'C'
      when substring(conta_contabil, 1, 1) in ('2', '4', '6', '8') and saldo_atual > 0 then 'C'
      when substring(conta_contabil, 1, 1) in ('2', '4', '6', '8') and saldo_atual < 0 then 'D'
      else ''
    end
where  remessa = {{remessa}}
    and natureza_saldo_anterior is null;

create table if not exists
pcasp
(
    exercicio usmallint,
    conta_contabil varchar(24),
    especificacao varchar(148),
    tipo_nivel char,
    nivel usmallint,
    escrituracao char,
    natureza_informacao char,
    indicador_superavit char
);

delete from pcasp where exercicio = {{exercicio}};

insert into pcasp
(
    exercicio,
    conta_contabil,
    especificacao,
    tipo_nivel,
    nivel,
    escrituracao,
    natureza_informacao,
    indicador_superavit
)
select distinct
    cast(substring(cast(remessa as varchar(6)), 1, 4) as usmallint),
    conta_contabil,
    especificacao,
    tipo_nivel,
    nivel,
    escrituracao,
    natureza_informacao,
    indicador_superavit
from balver
where remessa = {{remessa}}
order by conta_contabil asc;

delete from balver where escrituracao like 'N';