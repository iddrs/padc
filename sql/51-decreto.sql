create table if not exists
decreto
(
    remessa uinteger,
    entidade varchar(4),
    nr_lei varchar(20),
    data_lei date,
    nr_decreto varchar(20),
    data_decreto date,
    valor_credito decimal(11, 2),
    valor_reducao decimal(11, 2),
    tipo_credito utinyint,
    nome_tipo_credito varchar(30),
    origem_recurso utinyint,
    nome_origem_recurso varchar(30),
    tipo_alteracao utinyint,
    nome_tipo_alteracao varchar(30),
    valor_alteracao decimal(11, 2),
    data_reabertura date,
    valor_reabertura decimal(11, 2),
    exercicio_recurso_credito utinyint,
    nome_exercicio_recurso_credito varchar(30),
    fonte_recurso_credito usmallint,
    nome_fonte_recurso_credito varchar(80),
    exercicio_recurso_reducao utinyint,
    nome_exercicio_recurso_reducao varchar(30),
    fonte_recurso_reducao usmallint,
    nome_fonte_recurso_reducao varchar(80),
    data_operacao date
);

delete from decreto where remessa = {{remessa}};

insert into decreto
(
    remessa,
    entidade,
    nr_lei,
    data_lei,
    nr_decreto,
    data_decreto,
    valor_credito,
    valor_reducao,
    tipo_credito,
    origem_recurso,
    tipo_alteracao,
    valor_alteracao,
    data_reabertura,
    valor_reabertura,
    exercicio_recurso_credito,
    fonte_recurso_credito,
    exercicio_recurso_reducao,
    fonte_recurso_reducao,
    data_operacao
)
select
    remessa,
    entidade,
    trim(substring(raw_data, 1, 20)),
    make_date(cast(substring(raw_data, 25, 4) as usmallint), cast(substring(raw_data, 23, 2) as utinyint), cast(substring(raw_data, 21, 2) as utinyint)),
    trim(substring(raw_data, 29, 20)),
    make_date(cast(substring(raw_data, 53, 4) as usmallint), cast(substring(raw_data, 51, 2) as utinyint), cast(substring(raw_data, 49, 2) as utinyint)),
    round(cast(substring(raw_data, 57, 13) as hugeint) / 100, 2),
    round(cast(substring(raw_data, 70, 13) as hugeint) / 100, 2),
    substring(raw_data, 83 ,1),
    substring(raw_data, 84 ,1),
    substring(raw_data, 85 ,1),
    round(cast(substring(raw_data, 86, 13) as hugeint) / 100, 2),
    case
        when substring(raw_data, 99, 8) = '00000000' then null
        else make_date(cast(substring(raw_data, 103, 4) as usmallint), cast(substring(raw_data, 101, 2) as utinyint), cast(substring(raw_data, 99, 2) as utinyint))
    end,
    round(cast(substring(raw_data, 107, 13) as hugeint) / 100, 2),
    substring(raw_data, 128, 1),
    substring(raw_data, 129, 3),
    substring(raw_data, 132, 1),
    substring(raw_data, 133, 3),
    case
        when substring(raw_data, 136, 8) = '00000000' then null
        else make_date(cast(substring(raw_data, 140, 4) as usmallint), cast(substring(raw_data, 138, 2) as utinyint), cast(substring(raw_data, 136, 2) as utinyint))
    end
from cache
where arquivo like 'decreto';

update decreto
set entidade = case
                   when fonte_recurso_credito in (800, 801, 802, 803, 804) or fonte_recurso_credito in (800, 801, 802, 803, 804) then 'fpsm'
                   else 'pm'
    end
where remessa = {{remessa}}
  and entidade is null or entidade like '';

update decreto t
set
    nome_exercicio_recurso_credito = (select nome from exercicio_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and exercicio_recurso = t.exercicio_recurso_credito limit 1),
    nome_fonte_recurso_credito = (select nome from fonte_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and fonte_recurso = t.fonte_recurso_credito limit 1),
    nome_exercicio_recurso_reducao = (select nome from exercicio_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and exercicio_recurso = t.exercicio_recurso_reducao limit 1),
    nome_fonte_recurso_reducao = (select nome from fonte_recurso where exercicio = cast(substring(cast(t.remessa as varchar(6)), 1, 4) as usmallint) and fonte_recurso = t.fonte_recurso_reducao limit 1),
    nome_tipo_credito = case tipo_credito
    when 0 then 'Não se aplica'
    when 1 then 'Suplementar'
    when 2 then 'Especial'
    when 3 then 'Extraordinário'
    else null
end,
    nome_origem_recurso = case origem_recurso
                            when 0 then 'Não se aplica'
                            when 1 then 'Superávit financeiro'
                            when 2 then 'Excesso de arrecadação'
                            when 3 then 'Operação de crédito'
                            when 4 then 'Auxílios e convênios'
                            when 5 then 'Redução/suplementação na mesma entidade'
                            when 6 then 'Redução/suplementação entre entidades'
                            else null
end,
    nome_tipo_alteracao = case tipo_alteracao
                            when 0 then 'Não se aplica'
                            when 1 then 'Transferência'
                            when 2 then 'Transposição'
                            when 3 then 'Remanejamento'
                            else null
end

where nome_exercicio_recurso_credito is null or nome_exercicio_recurso_credito like '';
