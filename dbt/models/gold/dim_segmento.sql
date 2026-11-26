-- Segmentos UNSPSC (el primer nivel del clasificador de bienes y servicios).
select codigo_segmento, segmento, tipo_compra
from {{ ref('segmentos_unspsc') }}