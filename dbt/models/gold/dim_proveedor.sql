-- Una fila por proveedor. Las personas naturales aparecen sin nombre.
select
    id_proveedor,
    tipo_proveedor,
    coalesce(nombre_proveedor, tipo_proveedor) as nombre_proveedor,
    nit_proveedor,
    es_pyme,
    es_grupo
from {{ ref('contratos') }}
where id_proveedor is not null
qualify row_number() over (
    partition by id_proveedor
    order by fecha_ultima_actualizacion desc, _ingerido_en desc, id_contrato desc
) = 1