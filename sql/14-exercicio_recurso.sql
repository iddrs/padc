install excel;
load excel;
create table if not exists
exercicio_recurso
(
    exercicio usmallint,
    exercicio_recurso utinyint,
    nome varchar(80)
);

delete from exercicio_recurso;

insert into exercicio_recurso
(
    exercicio,
    exercicio_recurso,
    nome
)
select
    *
from read_xlsx('external_data.xlsx', header = true, sheet = 'exercicio_recurso');