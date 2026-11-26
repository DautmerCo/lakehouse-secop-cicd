-- Calendario completo desde el año de la primera firma hasta el de la última.
with limites as (
    select
        make_date(year(min(fecha_firma)), 1, 1)   as desde,
        make_date(year(max(fecha_firma)), 12, 31) as hasta
    from {{ ref('contratos') }}
),

fechas as (
    select explode(sequence(desde, hasta, interval 1 day)) as fecha
    from limites
)

select
    fecha,
    year(fecha)                         as anio,
    quarter(fecha)                      as trimestre,
    month(fecha)                        as mes,
    element_at(array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio',
                     'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
               month(fecha))            as nombre_mes,
    date_format(fecha, 'yyyy-MM')       as anio_mes,
    dayofweek(fecha) in (1, 7)          as es_fin_de_semana
from fechas