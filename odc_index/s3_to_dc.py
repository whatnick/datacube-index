#!/usr/bin/env python3
"""Build S3 iterators using odc-tools
and index datasets found into RDS
"""
import sys

import click
from odc.aio import S3Fetcher
from odc.aws._find import parse_query, norm_predicate


@click.command("s3-to-dc")
@click.argument("uri", type=str, nargs=1)
@click.argument("product", type=str, nargs=1)
def cli(uri, product):
    """ Iterate through files in an S3 bucket and add them to datacube"""
    # Get a generator from supplied S3 Uri for metadata definitions
    try:
        qq = parse_query(uri)
    except ValueError as e:
        click.echo(str(e), err=True)
        sys.exit(1)

    # Consume generator to add YAML's to Datacube


if __name__ == "__main__":
    cli()
