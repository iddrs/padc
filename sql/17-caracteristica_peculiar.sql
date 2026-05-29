install excel;
load excel;
create table if not exists
    caracteristica_peculiar
(
    exercicio usmallint,
    caracteristica_peculiar uinteger,
    nome varchar(80)
);

delete from caracteristica_peculiar;

insert into caracteristica_peculiar
(
    exercicio,
    caracteristica_peculiar,
    nome
)
select
    *
from read_xlsx('external_data.xlsx', header = true, sheet = 'caracteristica_peculiar');