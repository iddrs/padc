create table if not exists
balrec
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
    tipo_nivel char,
    nivel usmallint,
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
    receita_orcada decimal(11, 2),
    previsao_atualizada decimal(11, 2),
    receita_realizada decimal(11, 2),
    dif_realizada_orcada decimal(11, 2),
    dif_realizada_atualizada decimal(11, 2)
);

delete from balrec where remessa = {{remessa}};

insert into balrec
(
    remessa,
    entidade,
    codigo_receita,
    orgao,
    uniorcam,
    receita_orcada,
    receita_realizada,
    especificacao,
    tipo_nivel,
    nivel,
    deducao,
    previsao_atualizada,
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
    trim(substring(raw_data, 55, 170)),
    upper(substring(raw_data, 225, 1)),
    substring(raw_data, 226, 2),
    substring(raw_data, 228, 3),
    round(cast(substring(raw_data, 231, 13) as hugeint) / 100, 2),
    substring(raw_data, 248, 1),
    substring(raw_data, 249, 3),
    substring(raw_data, 252, 4),
    upper(substring(raw_data, 256, 4)),
from cache
where arquivo like 'bal_rec';

update balrec
set entidade = case orgao
                   when 1 then 'cm'
                   when 12 then 'fpsm'
                   when 50 then 'fpsm'
                   else 'pm'
    end
where remessa = {{remessa}}
  and entidade is null or entidade like '';

update balrec
set natureza_receita = case
        when left(codigo_receita, 1) = '7' then '1' || substring(codigo_receita, 2)
        when left(codigo_receita, 1) = '8' then '2' || substring(codigo_receita, 2)
        else codigo_receita
    end
where natureza_receita is null;

create table if not exists
ementario_receita
(
    exercicio usmallint,
    codigo_receita varchar(23),
    natureza_receita varchar(23),
    especificacao varchar(170),
    tipo_nivel char,
    nivel usmallint,
    exercicio_recurso utinyint,
    fonte_recurso usmallint,
    codigo_orcamentario usmallint,
    emenda_parlamentar usmallint
);

delete from ementario_receita where exercicio = {{exercicio}};

insert into ementario_receita
(
    exercicio,
    codigo_receita,
    natureza_receita,
    especificacao,
    tipo_nivel,
    nivel,
    exercicio_recurso,
    fonte_recurso,
    codigo_orcamentario,
    emenda_parlamentar
)
select distinct
    cast(substring(cast(remessa as varchar(6)), 1, 4) as usmallint),
    codigo_receita,
    natureza_receita,
    especificacao,
    tipo_nivel,
    nivel,
    exercicio_recurso,
    fonte_recurso,
    codigo_orcamentario,
    emenda_parlamentar
from balrec
where remessa = {{remessa}}
order by codigo_receita asc;

delete from balrec where tipo_nivel like 'S';

update balrec
set
    dif_realizada_orcada = receita_realizada - receita_orcada,
    dif_realizada_atualizada = receita_realizada - previsao_atualizada
where remessa = {{remessa}};

update balrec t
set
    nome_orgao = (select nome from orgao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and orgao = t.orgao limit 1),
    nome_uniorcam = (select nome from uniorcam where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and uniorcam = t.uniorcam limit 1),
    nome_exercicio_recurso = (select nome from exercicio_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and exercicio_recurso = t.exercicio_recurso limit 1),
    nome_fonte_recurso = (select nome from fonte_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and fonte_recurso = t.fonte_recurso limit 1),
    nome_codigo_orcamentario = (select nome from codigo_orcamentario where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and codigo_orcamentario = t.codigo_orcamentario limit 1),
    nome_deducao = (select nome from deducao where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and deducao = t.deducao limit 1),
    nome_emenda_parlamentar = (select nome from emenda_parlamentar where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and emenda_parlamentar = t.emenda_parlamentar limit 1)
where nome_orgao is null or nome_orgao like '';
