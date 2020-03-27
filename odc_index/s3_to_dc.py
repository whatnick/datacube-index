"""Build S3 iterators using odc-tools
and index datasets found into RDS
"""
import click
from odc.aio import S3Fetcher
from odc.aws._find import parse_query, norm_predicate


@click.command("s3-to-dc")
@click.argument("uri", type=str, nargs=1)
@click.argument("product", type=str, nargs=1)
def cli(uri, product):
    """ Iterate through files in an S3 bucket and add them to datacube"""
    pass


if __name__ == "__main__":
    cli()
