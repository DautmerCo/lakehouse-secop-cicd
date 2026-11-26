-- Un contrato no puede terminar antes de empezar.
select id_contrato, fecha_inicio, fecha_fin
from {{ ref('contratos') }}
where fecha_fin < fecha_inicio