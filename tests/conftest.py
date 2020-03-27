import time
import logging as LOG

import pytest


@pytest.fixture
def super_mock_s3():
    """
    Start a mock S3 server that can be used from within python and C code.
    To avoid any extra configuration, this requires hosts file entries for the default hostnames
    used by S3, *and* environment variables pointing to alternative SSL keys.
    This can be easily done with Docker, but might be better managed with docker-compose.
    We could potentially use https://github.com/adobe/S3Mock in docker instead of moto.
    """
    import socket
    import subprocess
    import os

    # Must run with patched S3 hosts
    hosts_redirected = (
        socket.gethostbyname("s3.amazonaws.com") == "127.0.0.1"
        and socket.gethostbyname("mybucket.s3.amazonaws.com") == "127.0.0.1"
    )
    environment_variables_set = (
        "AWS_CA_BUNDLE" in os.environ and "CURL_CA_BUNDLE" in os.environ
    )
    if not hosts_redirected or not environment_variables_set:
        pytest.skip(
            "super_mock_s3 requires hostnames and environment variables to be set"
        )

    p = subprocess.Popen(
        [
            "moto_server",
            "-p",
            "443",
            "-s",
            "--ssl-cert",
            "keys/server.pem",
            "--ssl-key",
            "keys/server-key.pem",
            "s3",
        ]
    )
    time.sleep(1)
    LOG.debug("Started moto_server for mocking s3")
    yield
    p.kill()
