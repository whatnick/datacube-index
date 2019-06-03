#!/bin/bash
# Wraps the update_ranges.sh script by passing in environment variables
# from the Docker's environment variables

indexing/update_ranges.sh \
-u "$DC_INDEX_PROTOCOL" \
-b "$DC_S3_INDEX_BUCKET" \
-p "$DC_S3_INDEX_PREFIX" \
-s "$DC_S3_INDEX_SUFFIX" \
-y "$DC_INDEX_YAML_SAFETY" \
-i "$DC_S3_IGNORE_SUFFIX" \
-d "$DC_RANGES_PRODUCT" \
-m "$DC_RANGES_MULTIPRODUCT" \
-l "$DC_IGNORE_LINEAGE" \
-e "$DC_EXCLUDE_PRODUCT" \
-n "$DC_THREDDS_DAYS"
