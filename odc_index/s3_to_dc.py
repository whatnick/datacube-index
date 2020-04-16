#!/usr/bin/env python3
"""Build S3 iterators using odc-tools
and index datasets found into RDS
"""
import sys
import logging
from typing import Tuple

import click
from odc.aio import s3_find_glob, S3Fetcher
from odc.index import from_yaml_doc_stream
from datacube import Datacube


def dump_to_odc(data_stream, dc: Datacube, product: str) -> Tuple[int, int]:
    # TODO: Get right combination of flags for **kwargs in low validation/no-lineage mode
    expand_stream = ((d.url, d.data) for d in data_stream if d.data is not None)

    # TODO: Apply the eo3 transform
    ds_stream = from_yaml_doc_stream(
        expand_stream,
        dc.index,
        transform=None,
        products=[product],
        fail_on_missing_lineage=True,
        verify_lineage=False,
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


@click.command("s3-to-dc")
@click.argument("uri", type=str, nargs=1)
@click.argument("product", type=str, nargs=1)
def cli(uri, product):
    """ Iterate through files in an S3 bucket and add them to datacube"""
    # TODO: Have eo3 argument OR autodetect

    # Get a generator from supplied S3 Uri for metadata definitions
    fetcher = S3Fetcher()

    # TODO: Share Fetcher
    s3_obj_stream = s3_find_glob(uri, False)

    # Extract URL's from output of iterator before passing to Fetcher
    s3_url_stream = (o.url for o in s3_obj_stream)

    # TODO: Capture S3 URL's in batches and perform bulk_location_has

    # Consume generator and fetch YAML's
    dc = Datacube()
    added, failed = dump_to_odc(fetcher(s3_url_stream), product, dc)
    print(f"Added {added} Datasets, Failed {failed} Datasets")


if __name__ == "__main__":
    cli()
