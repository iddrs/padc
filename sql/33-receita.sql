create table if not exists
receita
(
    remessa uinteger,
    entidade varchar(4),
    orgao usmallint,
    nome_orgao varchar(80),
    uniorcam usmallint,
    nome_uniorcam varchar(80),
    codigo_receita varchar(23),
    natureza_receita varchar(23),
    especificacao varchar(170),
    deducao utinyint,
    nome_deducao varchar(30),
    exercicio_recurso utinyint,
    nome_exercicio_recurso varchar(30),
    fonte_recurso usmallint,
    nome_fonte_recurso varchar(80),
    codigo_orcamentario usmallint,
    nome_codigo_orcamentario varchar(255),
    emenda_parlamentar usmallint,
    nome_emenda_parlamentar varchar(80),
    meta_jan decimal(11, 2),
    meta_fev decimal(11, 2),
    meta_mar decimal(11, 2),
    meta_abr decimal(11, 2),
    meta_mai decimal(11, 2),
    meta_jun decimal(11, 2),
    meta_jul decimal(11, 2),
    meta_ago decimal(11, 2),
    meta_set decimal(11, 2),
    meta_out decimal(11, 2),
    meta_nov decimal(11, 2),
    meta_dez decimal(11, 2),
    meta_1bim decimal(11, 2),
    meta_2bim decimal(11, 2),
    meta_3bim decimal(11, 2),
    meta_4bim decimal(11, 2),
    meta_5bim decimal(11, 2),
    meta_6bim decimal(11, 2),
    meta_total decimal(11, 2),
    realizada_jan decimal(11, 2),
    realizada_fev decimal(11, 2),
    realizada_mar decimal(11, 2),
    realizada_abr decimal(11, 2),
    realizada_mai decimal(11, 2),
    realizada_jun decimal(11, 2),
    realizada_jul decimal(11, 2),
    realizada_ago decimal(11, 2),
    realizada_set decimal(11, 2),
    realizada_out decimal(11, 2),
    realizada_nov decimal(11, 2),
    realizada_dez decimal(11, 2),
    realizada_total decimal(11, 2),
    dif_realizada_meta decimal(11, 2)
);

delete from receita where remessa = {{remessa}};

insert into receita
(
    remessa,
    entidade,
    codigo_receita,
    orgao,
    uniorcam,
    realizada_jan,
    realizada_fev,
    realizada_mar,
    realizada_abr,
    realizada_mai,
    realizada_jun,
    realizada_jul,
    realizada_ago,
    realizada_set,
    realizada_out,
    realizada_nov,
    realizada_dez,
    meta_1bim,
    meta_2bim,
    meta_3bim,
    meta_4bim,
    meta_5bim,
    meta_6bim,
    deducao,
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
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 5, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 7, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 8, 1) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 9, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 11, 2) || '.' ||
    substring(rpad(ltrim(substring(raw_data, 1, 20), '0'), 20, '0'), 13, 2),
    substring(raw_data, 21, 2),
    substring(raw_data, 21, 4),
    round(cast(substring(raw_data, 25, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 38, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 51, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 64, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 77, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 90, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 103, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 116, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 129, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 142, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 155, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 168, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 181, 12) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 193, 12) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 205, 12) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 217, 12) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 229, 12) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 241, 12) as hugeint) / 100, 2),
    substring(raw_data, 253, 3),
    substring(raw_data, 264, 1),
    substring(raw_data, 265, 3),
    substring(raw_data, 268, 4),
    substring(raw_data, 272, 4)
from cache
where arquivo like 'receita';

delete from receita where fonte_recurso = 0;

update receita
set entidade = case orgao
                   when 1 then 'cm'
                   when 12 then 'fpsm'
                   when 50 then 'fpsm'
                   else 'pm'
    end
where remessa = {{remessa}}
  and entidade is null or entidade like '';

update receita
set natureza_receita = case
        when left(codigo_receita, 1) = '7' then '1' || substring(codigo_receita, 2)
        when left(codigo_receita, 1) = '8' then '2' || substring(codigo_receita, 2)
        else codigo_receita
    end,
meta_jan = meta_1bim / 2,
meta_fev = meta_1bim / 2,
meta_mar = meta_2bim / 2,
meta_abr = meta_2bim / 2,
meta_mai = meta_3bim / 2,
meta_jun = meta_3bim / 2,
meta_jul = meta_4bim / 2,
meta_ago = meta_4bim / 2,
meta_set = meta_5bim / 2,
meta_out = meta_5bim / 2,
meta_nov = meta_6bim / 2,
meta_dez = meta_6bim / 2,
realizada_total = realizada_jan
       + realizada_fev
       + realizada_mar
       + realizada_abr
       + realizada_mai
       + realizada_jun
       + realizada_jul
       + realizada_ago
       + realizada_set
       + realizada_out
       + realizada_nov
       + realizada_dez,
meta_total = meta_1bim
       + meta_2bim
       + meta_3bim
       + meta_4bim
       + meta_5bim
       + meta_6bim
where natureza_receita is null;

update receita
set dif_realizada_meta = realizada_total - meta_total
where dif_realizada_meta is null;

update receita t
set
    nome_orgao = (select nome from orgao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and orgao = t.orgao limit 1),
    nome_uniorcam = (select nome from uniorcam where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and uniorcam = t.uniorcam limit 1),
    especificacao = (select especificacao from balrec where remessa = t.remessa and codigo_receita = t.codigo_receita limit 1),
    nome_exercicio_recurso = (select nome from exercicio_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and exercicio_recurso = t.exercicio_recurso limit 1),
    nome_fonte_recurso = (select nome from fonte_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and fonte_recurso = t.fonte_recurso limit 1),
    nome_codigo_orcamentario = (select nome from codigo_orcamentario where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and codigo_orcamentario = t.codigo_orcamentario limit 1),
    nome_deducao = (select nome from deducao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and deducao = t.deducao limit 1),
    nome_emenda_parlamentar = (select nome from emenda_parlamentar where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and emenda_parlamentar = t.emenda_parlamentar limit 1)
where nome_orgao is null or nome_orgao like '';
