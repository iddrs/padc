install excel;
load excel;
create table if not exists
    despesa_funcionario
(
    exercicio usmallint,
    despesa_funcionario varchar(3),
    nome varchar(80)
);

delete from despesa_funcionario;

insert into despesa_funcionario
(
    exercicio,
    despesa_funcionario,
    nome
)
select
    *
from read_xlsx('external_data.xlsx', header = true, sheet = 'despesa_funcionario');