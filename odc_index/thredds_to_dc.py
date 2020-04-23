"""Crawl Thredds for prefixes and fetch YAML's for indexing
and dump them into a Datacube instance
"""
import sys
import logging
from typing import Tuple

import click
from odc.thredds import thredds_find_glob, download_yamls
from odc.index import from_yaml_doc_stream
from datacube import Datacube


def dump_list_to_odc(yaml_content_list: list, dc: Datacube, product: str):
    expand_stream = (
        ("https://" + d[1], d[0]) for d in yaml_content_list if d[0] is not None
    )

    ds_stream = from_yaml_doc_stream(
        expand_stream,
        dc.index,
        transform=None,
        products=[product],
        fail_on_missing_lineage=False,
        skip_lineage=True,
    )
    ds_added = 0
    ds_failed = 0
    # Consume chained streams to DB
    for result in ds_stream:
        ds, err = result
        if err is not None:
            logging.error(err)
            ds_failed += 1
        else:
            logging.info(ds)
            # TODO: Potentially wrap this in transactions and batch to DB
            # TODO: Capture UUID's from YAML and perform a bulk has
            try:
                dc.index.datasets.add(ds)
                ds_added += 1
            except Exception as e:
                logging.error(e)
                ds_failed += 1

    return ds_added, ds_failed


@click.command("thredds-to-dc")
@click.argument("uri", type=str, nargs=1)
@click.argument("product", type=str, nargs=1)
def cli(uri, product):
    skips = [".*NBAR.*", ".*SUPPLEMENTARY.*", ".*NBART.*", ".*/QA/.*"]
    select = [".*ARD-METADATA.yaml"]
    print(f"Crawling {uri} on Thredds")
    yaml_urls = thredds_find_glob(uri, skips, select)
    print(f"Found {len(yaml_urls)} datasets")

    yaml_contents = download_yamls(yaml_urls)

    # Consume generator and fetch YAML's
    dc = Datacube()
    added, failed = dump_list_to_odc(yaml_contents, dc, product)
    print(f"Added {added} Datasets, Failed {failed} Datasets")
