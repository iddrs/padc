create table if not exists
credor
(
    exercicio usmallint,
    credor uinteger,
    nome varchar(60),
    cnpj varchar(18),
    cpf varchar(14),
    inscricao_estadual uhugeint,
    inscricao_municipal uhugeint,
    endereco varchar(50),
    cidade varchar(30),
    uf varchar(2),
    cep varchar(10),
    tipo_credor utinyint,
    tipo_pessoa utinyint
);

insert into credor
(
    exercicio,
    credor,
    nome,
    cnpj,
    cpf,
    inscricao_estadual,
    inscricao_municipal,
    endereco,
    cidade,
    uf,
    cep,
    tipo_credor,
    tipo_pessoa
)
select
    cast(substring(cast(remessa as varchar(6)), 1, 4) as usmallint),
    substring(raw_data, 1, 10),
    trim(substring(raw_data, 11, 60)),
    case
        when starts_with(substring(raw_data, 71, 14), '000') then null
        else substring(raw_data, 71, 2) || '.' ||
             substring(raw_data, 73, 3) || '.' ||
             substring(raw_data, 76, 3) || '/' ||
             substring(raw_data, 79, 4) || '-' ||
             substring(raw_data, 83, 2)
    end,
    case
        when starts_with(substring(raw_data, 71, 14), '000') then substring(raw_data, 74, 3) || '.' ||
                                                                  substring(raw_data, 77, 3) || '.' ||
                                                                  substring(raw_data, 80, 3) || '-' ||
                                                                  substring(raw_data, 83, 2)
        else null
    end,
    trim(substring(raw_data, 85, 15)),
    trim(substring(raw_data, 100, 15)),
    trim(substring(raw_data, 115, 50)),
    upper(substring(raw_data, 165, 30)),
    upper(substring(raw_data, 195, 2)),
    substring(raw_data, 197, 2) || '.' ||
    substring(raw_data, 199, 3) || '-' ||
    substring(raw_data, 202, 3),
    substring(raw_data, 235, 2),
    substring(raw_data, 237, 2)
from cache
where arquivo like 'credor';

CREATE TABLE credor_temp AS
SELECT DISTINCT * FROM credor;

DROP TABLE credor;

ALTER TABLE credor_temp RENAME TO credor;