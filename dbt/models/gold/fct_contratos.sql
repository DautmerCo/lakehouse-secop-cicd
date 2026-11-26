{{ config(
    materialized='incremental',
    unique_key='id_contrato',
    incremental_strategy='merge'
) }}

select
    id_contrato,

    -- llaves a las dimensiones
    codigo_entidad,
    id_proveedor,
    fecha_firma,
    case when codigo_unspsc like 'V1.%' then substr(codigo_unspsc, 4, 2) else '00' end
                                                        as codigo_segmento,

    -- atributos del contrato
    estado_contrato,
    modalidad_de_contratacion,
    modalidad_de_contratacion ilike 'Contratación directa%'
                                                        as es_contratacion_directa,
    tipo_de_contrato,
    origen_de_los_recursos,
    destino_gasto,
    es_posconflicto,
    objeto_del_contrato,
    url_proceso,
    fecha_inicio,
    fecha_fin,
    datediff(fecha_fin, fecha_inicio)                   as duracion_dias,
    dias_adicionados,

    -- valores en pesos
    valor_contrato,
    valor_facturado,
    valor_pagado,
    valor_pendiente_pago,

    _ingerido_en
from {{ ref('contratos') }}
{% if is_incremental() %}
where _ingerido_en > (select max(_ingerido_en) from {{ this }})
{% endif %}