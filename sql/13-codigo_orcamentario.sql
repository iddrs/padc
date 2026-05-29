install excel;
load excel;
create table if not exists
codigo_orcamentario
(
    exercicio usmallint,
    codigo_orcamentario uinteger,
    nome varchar(80)
);

delete from codigo_orcamentario;

insert into codigo_orcamentario
(
    exercicio,
    codigo_orcamentario,
    nome
)
select
    *
from read_xlsx('external_data.xlsx', header = true, sheet = 'codigo_orcamentario');