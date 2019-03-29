docker rmi gs_index
docker rmi s3_index

cd examples/gs

docker-compose up -d

# until docker logs docker_index_1 | grep -m 1 "Updating range for:  low_tide_comp_20p"; do sleep 10; done
