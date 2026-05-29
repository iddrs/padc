create table if not exists
bverenc
(
    remessa uinteger,
    entidade varchar(4),
    conta_contabil varchar(24),
    orgao usmallint,
    nome_orgao varchar(80),
    uniorcam usmallint,
    nome_uniorcam varchar(80),
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
    nome_natureza_informacao varchar(30),
    indicador_superavit char,
    nome_indicador_superavit varchar(30),
    exercicio_recurso utinyint,
    nome_exercicio_recurso varchar(30),
    fonte_recurso usmallint,
    nome_fonte_recurso varchar(80),
    codigo_orcamentario usmallint,
    nome_codigo_orcamentario varchar(80),
    emenda_parlamentar usmallint,
    nome_emenda_parlamentar varchar(80)
);

delete from bverenc where remessa = {{remessa}};

insert into bverenc
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
where arquivo like 'bver_enc';

update bverenc
set entidade = case orgao
                   when 1 then 'cm'
                   when 12 then 'fpsm'
                   when 50 then 'fpsm'
                   else 'pm'
    end
where remessa = {{remessa}}
  and entidade is null or entidade like '';

update bverenc
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

update bverenc
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

delete from bverenc where escrituracao like 'N';

update bverenc t
set
    nome_orgao = (select nome from orgao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and orgao = t.orgao limit 1),
    nome_uniorcam = (select nome from uniorcam where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and uniorcam = t.uniorcam limit 1),
    nome_exercicio_recurso = (select nome from exercicio_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and exercicio_recurso = t.exercicio_recurso limit 1),
    nome_fonte_recurso = (select nome from fonte_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and fonte_recurso = t.fonte_recurso limit 1),
    nome_codigo_orcamentario = (select nome from codigo_orcamentario where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and codigo_orcamentario = t.codigo_orcamentario limit 1),
    nome_emenda_parlamentar = (select nome from emenda_parlamentar where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and emenda_parlamentar = t.emenda_parlamentar limit 1),
    nome_natureza_informacao = case natureza_informacao when 'P' then 'Patrimonial' when 'O' then 'Orçamentária' when 'C' then 'Controle' else null end,
    nome_indicador_superavit = case indicador_superavit when 'F' then 'Financeiro' when 'P' then 'Permanente' else null end
where nome_orgao is null or nome_orgao like '';
