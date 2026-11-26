-- Una fila por entidad contratante, con sus atributos más recientes.
select
    codigo_entidad,
    nit_entidad,
    nombre_entidad,
    departamento,
    ciudad,
    orden,
    sector,
    rama,
    entidad_centralizada
from {{ ref('contratos') }}
qualify row_number() over (
    partition by codigo_entidad
    order by fecha_ultima_actualizacion desc, _ingerido_en desc, id_contrato desc
) = 1