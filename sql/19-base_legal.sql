install excel;
load excel;
create table if not exists
    base_legal
(
    exercicio usmallint,
    base_legal uinteger,
    nome varchar(80)
);

delete from base_legal;

insert into base_legal
(
    exercicio,
    base_legal,
    nome
)
select
    *
from read_xlsx('external_data.xlsx', header = true, sheet = 'base_legal');