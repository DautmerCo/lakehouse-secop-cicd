{# "terminado" -> "Terminado", sin tocar el resto ("Salud y Protección Social" queda igual). #}
{% macro capitalizar(columna) -%}
    concat(upper(substr(trim({{ columna }}), 1, 1)), substr(trim({{ columna }}), 2))
{%- endmacro %}