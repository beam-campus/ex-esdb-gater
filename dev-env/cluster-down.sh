#! /bin/bash

docker-compose \
  -f ex-esdb-volumes.yaml \
  -f ex-esdb-network.yaml \
  -f ex-esdb-cluster.yaml \
  --profile cluster \
  -p cluster \
  down
