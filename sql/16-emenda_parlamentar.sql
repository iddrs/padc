install excel;
load excel;
create table if not exists
    emenda_parlamentar
(
    exercicio usmallint,
    emenda_parlamentar uinteger,
    nome varchar(80)
);

delete from emenda_parlamentar;

insert into emenda_parlamentar
(
    exercicio,
    emenda_parlamentar,
    nome
)
select
    *
from read_xlsx('external_data.xlsx', header = true, sheet = 'emenda_parlamentar');