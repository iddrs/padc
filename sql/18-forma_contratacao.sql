install excel;
load excel;
create table if not exists
    forma_contratacao
(
    exercicio usmallint,
    forma_contratacao varchar(3),
    nome varchar(80)
);

delete from forma_contratacao;

insert into forma_contratacao
(
    exercicio,
    forma_contratacao,
    nome
)
select
    *
from read_xlsx('external_data.xlsx', header = true, sheet = 'forma_contratacao');