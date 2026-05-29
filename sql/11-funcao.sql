install excel;
load excel;
create table if not exists
funcao
(
    exercicio usmallint,
    funcao utinyint,
    nome varchar(80)
);

delete from funcao;

insert into funcao
(
    exercicio,
    funcao,
    nome
)
select
    *
from read_xlsx('external_data.xlsx', header = true, sheet = 'funcao');