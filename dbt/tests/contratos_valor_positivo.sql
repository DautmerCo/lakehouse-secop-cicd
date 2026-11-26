-- Contratos con valor 0 o negativo: se reportan, pero no detienen el pipeline.
{{ config(severity='warn') }}

select id_contrato, valor_contrato
from {{ ref('contratos') }}
where valor_contrato <= 0