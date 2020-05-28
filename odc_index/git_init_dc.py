#!/usr/bin/env python3
"""This script allows creation of all metadata/products
in an ODC instance from a given CSV catalog definition
In local development activate <odc> conda environment
In kubernetes pod executor run from <datacube-index>
container  
"""
import sys
import logging
import csv

import requests
import click
from datacube import Datacube


@click.command("dc-from-git")
@click.argument("metadata_catalog", type=str, nargs=1)
@click.argument("product_catalog", type=str, nargs=1)
def cli(metadata_catalog, product_catalog):
    """ Use requests and datacube to directly place
    metadata / products into datacube """
    print("Adding Metadata")
    # TODO: Add Metadata from Datacube API
    print("Add Products")
    # TODO: Add Products from Datacube API
