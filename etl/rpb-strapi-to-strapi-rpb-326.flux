// Created full lookup table for RPB-326 (edited TSV from issue, replaced "und" with " ; "):
// - `sbt "runMain rpb.ETL etl/rpb-strapi-to-strapi-rpb-326.flux"`
// - `cat etl/maps/gndUri-to-broaderSpatial-additional.tsv >> etl/maps/gndUri-to-broaderSpatial.tsv`

// Then use for updates:
//- `sbt "runMain rpb.ETL etl/rpb-strapi-to-strapi.flux FIX_FILE=rpb-strapi-to-strapi-rpb-326.fix TYPE=articles HOST=$HOST API_TOKEN=$API_TOKEN`

default outfile = "etl/maps/gndUri-to-broaderSpatial-allegro.tsv";
FLUX_DIR + "RPB-Export_HBZ_Tit.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix("

unless exists('f31?')
    reject()
end

do put_macro('filter_spatial')
    set_array('$[to]')
    copy_field('f31?', '$[to].$append')
    filter('$[to]', '^_r(..)_$', invert: 'true')
end

call_macro('filter_spatial', to: 'spatial')
replace_all('spatial.*','^_r[0-9]{2}_ _([0-9]*)n([0-9]|X)_$','https://d-nb.info/gnd/$1-$2')
replace_all('spatial.*','^_r[0-9]{2}_ _([0-9]*)_$','https://d-nb.info/gnd/$1')
lookup('spatial.*',
    'https://d-nb.info/gnd/4680138-8': 'https://d-nb.info/gnd/4116352-7',
    'https://d-nb.info/gnd/4108134-1': 'https://d-nb.info/gnd/4766893-3',
    'https://d-nb.info/gnd/4028839-0': 'https://d-nb.info/gnd/4028836-5')
filter(spatial, '^http')

if is_empty(spatial)
    reject()
end

call_macro('filter_spatial', to: 'broader')
replace_all('broader.*','^_r(96|99)_ _([0-9]*(n([0-9]|X)?))_$','https://rpb.lobid.org/spatial#n$2')
filter('broader', '^_r(96|99)_.*', invert: 'true') # non-GND 96/99
replace_all('broader.*','^_r([0-9]{2})_ _.+_$','https://rpb.lobid.org/spatial#n$1')
filter(broader, '^http')

retain('spatial.1', 'broader.1')

")
| encode-csv(includeRecordId="false", includeHeader="true", noQuotes="true", separator="\t")
| filter-duplicate-objects
| write(outfile)
;
