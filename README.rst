.. image:: https://img.shields.io/travis/opendatacube/datacube-index.svg
        :target: https://travis-ci.org/opendatacube/datacube-index

This code will generate a docker image that is used to index data into a datacube. It has code to perform the follow steps:

#. Crawl Thredds or S3 to find datasets.
#. Index them using `odc-tools <https://github.com/opendatacube/odc-tools>`_ into datacube.
#. Use `OWS Update ranges <https://datacube-ows.readthedocs.io/en/latest/usage.html#as-a-web-service-in-docker-with-layers-deployed>`_ to update layer extents for products in OWS managed tables.
