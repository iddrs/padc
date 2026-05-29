install excel;
load excel;
create table if not exists
    tipo_contrato
(
    exercicio usmallint,
    tipo_contrato varchar(1),
    nome varchar(80)
);

delete from tipo_contrato;

insert into tipo_contrato
(
    exercicio,
    tipo_contrato,
    nome
)
select
    *
from read_xlsx('external_data.xlsx', header = true, sheet = 'tipo_contrato');