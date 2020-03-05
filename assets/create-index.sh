#!/bin/bash

set -e

# Init system
datacube system init --no-init-users 2>&1

# Add product definitions to datacube
# URLS must be delimited with ':' and WITHOUT http(s)://
# Add product definitions to datacube
# URLS must be delimited with ':' and WITHOUT http(s)://
function add_products {
    mkdir -p firsttime/products

    read -ra URLS <<<"$PRODUCT_URLS"

    for U in "${URLS[@]}"
    do
        wget "$U" -O firsttime/products/"$(tr -cd 'a-f0-9' < /dev/urandom | head -c 16)".yaml
    done

    for file in firsttime/products/*
    do
        datacube product add "$file"
    done
}

add_products

# Generate WMS specific config
wms_config_file=/code/datacube_ows/ows_cfg.py
echo "Getting config from $WMS_CONFIG_URL"
curl -o "$wms_config_file" "$WMS_CONFIG_URL"
test -f "$wms_config_file" && echo "Found OWS Config"
if [ -z "$WMS_CONFIG_URL" ]; then
    echo "Getting config from $WMS_CONFIG_URL"
    [[ "$WMS_CONFIG_URL" =~ ^http ]] && ! test -f "$wms_config_file" && curl -o "$wms_config_file" "$WMS_CONFIG_URL"
fi
cd ..
PYTHONPATH=. python3 ./update_ranges.py --schema 2>&1 --role "$DB_ROLE" || echo "Warning: Can't create schema"

# Run index
indexing/update_ranges_wrapper.sh

set +e
