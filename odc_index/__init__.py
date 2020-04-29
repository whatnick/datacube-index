"""Functions used by s3_to_dc application
"""
import itertools

from odc.index import from_yaml_doc_stream, detect_eo3, prep_eo3
from datacube import Datacube
import yaml


def eo3_aware_yaml_doc_stream(data_stream, dc: Datacube, products: list, **kwargs):
    try:
        first = next(data_stream)
    except StopIteration:
        return []

    parsed = yaml.load(first[1], Loader=yaml.CLoader)
    transform = prep_eo3 if detect_eo3(parsed) else None
    data_stream = itertools.chain([first], data_stream)

    return from_yaml_doc_stream(
        data_stream, dc.index, transform=transform, products=products, **kwargs
    )


def bulk_has_location(loc_list: list, product: str) -> list:
    """Check a list of locations (from S3) against dataset_locations
    in datacube db to ensure data has not been indexed already

    Arguments:
        loc_list {list} -- List of YAML locations in S3
        product {str} -- Product name to check against

    Returns:
        list -- List of booleans with location check results
    """
    pass


def bulk_has_uuid(loc_list: list, product: str) -> list:
    """Fetch YAML uuid's from S3 using aiobotocore in parallel
    and check their presence in datacube using bulk_has
    https://datacube-core.readthedocs.io/en/latest/dev/api/generate/datacube.index._datasets.DatasetResource.bulk_has.html

    Arguments:
        loc_list {list} -- List of YAML locations in S3
        product {str} -- Product name to check against

    Returns:
        list -- List of booleans with location check results
    """
    uuid_list = _get_uuid_s3(loc_list)
    with Datacube() as dc:
        has_result = dc.index.datasets.bulk_has(uuid_list)

    return has_result


def _get_uuid_s3(loc_list: list) -> list:
    """Given list of S3 YAML's download and parse them into a list of UUID's for ODC.

    Arguments:
        loc_list {list} -- List of S3 YAML locations

    Returns:
        list -- List of ODC UUID's
    """
    return list(loc_list)
