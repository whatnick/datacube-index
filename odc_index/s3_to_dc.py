#!/usr/bin/env python3
"""Build S3 iterators using odc-tools
and index datasets found into RDS
"""
import sys

import click
from odc.aio import s3_find_glob


@click.command("s3-to-dc")
@click.argument("uri", type=str, nargs=1)
@click.argument("product", type=str, nargs=1)
def cli(uri, product):
    """ Iterate through files in an S3 bucket and add them to datacube"""
    # Get a generator from supplied S3 Uri for metadata definitions
    s3_yaml_stream = s3_find_glob(uri, False)

    # Consume generator to add YAML's to Datacube
    s3_uri_stream = (o.url for o in s3_yaml_stream)


if __name__ == "__main__":
    cli()
