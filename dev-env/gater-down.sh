#! /bin/bash

docker-compose \
  -f ex-esdb-volumes.yaml \
  -f ex-esdb-network.yaml \
  -f ex-esdb-gater-cluster.yaml \
  --profile gater \
  -p gater \
  down
