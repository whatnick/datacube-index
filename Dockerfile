FROM opendatacube/geobase:wheels as env_builder

COPY requirements-docker.txt /
RUN /usr/local/bin/env-build-tool new /requirements-docker.txt /env

ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Do the apt install process, including more recent Postgres/PostGIS
RUN apt-get update && apt-get install -y wget gnupg \
    && rm -rf /var/lib/apt/lists/*
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
    apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" \
    >> /etc/apt/sources.list.d/postgresql.list

ADD requirements-apt.txt /tmp/
RUN apt-get update \
    && sed 's/#.*//' /tmp/requirements-apt.txt | xargs apt-get install -y \
    && rm -rf /var/lib/apt/lists/*

# Use docker build cache more
RUN mkdir -p /code/{assets,odc_index,tests}
ADD ./tests/requirements.txt /code/tests/requirements.txt
ADD ./assets/requirements.txt /code/assets/requirements.txt
ADD ./odc_index/requirements.txt /code/odc_index/requirements.txt

# Install Python requirements
RUN /env/bin/pip install --extra-index-url https://packages.dea.ga.gov.au/ \
-r /code/odc_index/requirements.txt -r /code/tests/requirements.txt \
-r /code/assets/requirements.txt

# Set up a nice workdir, and only copy the things we care about in
ADD . /code

# Install the local package
RUN /env/bin/pip install /code

FROM opendatacube/geobase:runner
COPY --from=env_builder /env /env

ENV PATH="/env/bin:${PATH}"
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Install dea proto for indexing tools
COPY assets/update_ranges.sh /code/index/indexing/update_ranges.sh
COPY assets/update_ranges_wrapper.sh /code/index/indexing/update_ranges_wrapper.sh
COPY assets/create-index.sh /code/index/create-index.sh
