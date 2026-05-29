install excel;
load excel;
create table if not exists
subfuncao
(
    exercicio usmallint,
    subfuncao uinteger,
    nome varchar(80)
);

delete from subfuncao;

insert into subfuncao
(
    exercicio,
    subfuncao,
    nome
)
select
    *
from read_xlsx('external_data.xlsx', header = true, sheet = 'subfuncao');