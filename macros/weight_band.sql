{% macro weight_band(weight_kg) %}

    case
        when {{ weight_kg }} is null then 'unknown'
        when {{ weight_kg }} < 1  then '00-01 kg'
        when {{ weight_kg }} < 3  then '01-03 kg'
        when {{ weight_kg }} < 10 then '03-10 kg'
        when {{ weight_kg }} < 30 then '10-30 kg'
        else '30+ kg'
    end

{% endmacro %}