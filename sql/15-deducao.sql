install excel;
load excel;
create table if not exists
deducao
(
    exercicio usmallint,
    deducao utinyint,
    nome varchar(80)
);

delete from deducao;

insert into deducao
(
    exercicio,
    deducao,
    nome
)
select
    *
from read_xlsx('external_data.xlsx', header = true, sheet = 'deducao');