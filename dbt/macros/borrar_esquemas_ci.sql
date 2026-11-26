{% macro borrar_esquemas_ci() %}
    {% if target.name != 'ci' %}
        {{ exceptions.raise_compiler_error("Esta macro solo corre con --target ci") }}
    {% endif %}
    {% for capa in ['silver', 'gold'] %}
        {% do run_query('drop schema if exists ' ~ target.catalog ~ '.secop_ci_' ~ capa ~ ' cascade') %}
        {{ log('Borrado ' ~ target.catalog ~ '.secop_ci_' ~ capa, info=True) }}
    {% endfor %}
{% endmacro %}