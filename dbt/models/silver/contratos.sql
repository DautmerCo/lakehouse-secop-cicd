{{ config(
    materialized='incremental',
    unique_key='id_contrato',
    incremental_strategy='merge'
) }}

-- En cada ejecución solo se procesa lo que llegó a Bronze después de la anterior.
with nuevos as (
    select *
    from {{ source('bronze', 'contratos') }}
    {% if is_incremental() %}
    where _ingerido_en > (select max(_ingerido_en) from {{ this }})
    {% endif %}
),

-- Un contrato puede llegar en varias corridas: se conserva su versión más reciente.
ultima_version as (
    select *
    from nuevos
    qualify row_number() over (
        partition by id_contrato
        order by ultima_actualizacion desc, corrida desc
    ) = 1
)

select
    -- contrato
    id_contrato,
    referencia_del_contrato,
    proceso_de_compra,
    coalesce(get_json_object(urlproceso, '$.url'), urlproceso)  as url_proceso,
    {{ capitalizar('estado_contrato') }}                         as estado_contrato,
    tipo_de_contrato,
    modalidad_de_contratacion,
    codigo_de_categoria_principal                                as codigo_unspsc,
    objeto_del_contrato,

    -- entidad contratante
    try_cast(codigo_entidad as bigint)                           as codigo_entidad,
    nit_entidad,
    nombre_entidad,
    departamento,
    ciudad,
    orden,
    {{ capitalizar('sector') }}                                  as sector,
    rama,
    entidad_centralizada,

    -- proveedor: el nombre solo se conserva para empresas
    codigo_proveedor                                             as id_proveedor,
    case
        when tipodocproveedor = 'NIT' then 'Persona jurídica'
        when tipodocproveedor in ('No Definido', 'Otro') then 'Sin definir'
        else 'Persona natural'
    end                                                          as tipo_proveedor,
    case when tipodocproveedor = 'NIT' then documento_proveedor end   as nit_proveedor,
    case when tipodocproveedor = 'NIT' then proveedor_adjudicado end  as nombre_proveedor,
    es_pyme = 'Si'                                               as es_pyme,
    es_grupo = 'Si'                                              as es_grupo,

    -- fechas
    to_date(try_cast(fecha_de_firma as timestamp))               as fecha_firma,
    to_date(try_cast(fecha_de_inicio_del_contrato as timestamp)) as fecha_inicio,
    to_date(try_cast(fecha_de_fin_del_contrato as timestamp))    as fecha_fin,
    to_date(try_cast(ultima_actualizacion as timestamp))         as fecha_ultima_actualizacion,
    try_cast(dias_adicionados as int)                            as dias_adicionados,

    -- valores en pesos
    try_cast(valor_del_contrato as decimal(20, 2))               as valor_contrato,
    try_cast(valor_facturado as decimal(20, 2))                  as valor_facturado,
    try_cast(valor_pagado as decimal(20, 2))                     as valor_pagado,
    try_cast(valor_pendiente_de_pago as decimal(20, 2))          as valor_pendiente_pago,
    origen_de_los_recursos,
    destino_gasto,
    espostconflicto = 'Si'                                       as es_posconflicto,

    -- linaje
    corrida,
    _ingerido_en
from ultima_version