.. image:: https://github.com/opendatacube/datacube-index/workflows/Lint%20and%20Test%20Code/badge.svg?branch=master
        :target: https://github.com/opendatacube/datacube-index/actions?query=workflow%3A%22Lint+and+Test+Code%22

This code will generate a docker image that is used to index data into a datacube using `odc-tools <https://github.com/opendatacube/odc-tools>`_.
It has code to perform the follow steps:

#. Crawl S3 to find datasets using **s3-find** and produce a generator.
#. Index them using  into datacube using generator equivalent of **dc-index-from-tar** while skipping the tar file.
#. Crawl Thredds using `Thredds Crawler <https://github.com/ioos/thredds_crawler>`_ with NCI specific defaults (overrideable).
#. Use `OWS Update ranges <https://datacube-ows.readthedocs.io/en/latest/usage.html#as-a-web-service-in-docker-with-layers-deployed>`_ to update layer extents for products in OWS managed tables in a separate container.
#. Use `Explorer Summary generation <https://github.com/opendatacube/datacube-explorer/blob/ea57fb18a94c9a5b7c7cd9ac4a0f7b092c761fd4/cubedash/generate.py#L140>`_ to generate summaries.
#. The 3-containers are tied together by an `Airflow DAG <https://airflow.apache.org/docs/stable/concepts.html#dags>`_ using a `K8S Executor <https://airflow.apache.org/docs/1.10.1/kubernetes.html>`_.
