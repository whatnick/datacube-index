#!/usr/bin/env python3
"""Build S3 iterators using odc-tools
and index datasets found into RDS
"""
import sys

import click
from odc.aio import s3_find_glob, S3Fetcher
from odc.index import from_yaml_doc_stream
from datacube import Datacube

def dump_to_odc(data_stream, index):
    # TODO: Get right combination of flags for **kwargs in low validation/no-lineage mode
    expand_stream = ((d.url, d.data) for d in data_stream if d.data is not None)
    return from_yaml_doc_stream(expand_stream, index, transform=None)


@click.command("s3-to-dc")
@click.argument("uri", type=str, nargs=1)
@click.argument("product", type=str, nargs=1)
def cli(uri, product):
    """ Iterate through files in an S3 bucket and add them to datacube"""
    # Get a generator from supplied S3 Uri for metadata definitions
    fetcher = S3Fetcher()

    # TODO: Share Fetcher
    s3_obj_stream = s3_find_glob(uri, False)
    
    # Extract URL's from output of iterator before passing to Fetcher
    s3_url_stream = (o.url for o in s3_obj_stream)

    # Consume generator and fetch YAML's
    dc = Datacube()
    result_stream = dump_to_odc(fetcher(s3_url_stream), dc)
    for result in result_stream:
        print(result)


if __name__ == "__main__":
    cli()
