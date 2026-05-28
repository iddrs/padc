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
    origem_recurso utinyint,
    tipo_alteracao utinyint,
    valor_alteracao decimal(11, 2),
    data_reabertura date,
    valor_reabertura decimal(11, 2),
    exercicio_recurso_credito utinyint,
    fonte_recurso_credito usmallint,
    exercicio_recurso_reducao utinyint,
    fonte_recurso_reducao usmallint,
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
