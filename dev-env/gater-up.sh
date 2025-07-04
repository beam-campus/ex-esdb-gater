#! /bin/bash

## CLEAR ALL DATA
# echo "Clearing all data"
# sudo rm -rf /volume
docker-compose \
  -f ex-esdb-network.yaml \
  -f ex-esdb-gater.yaml \
  -f ex-esdb-gater-override.yaml \
  --profile gater \
  -p gater \
  down

docker-compose \
  -f ex-esdb-network.yaml \
  -f ex-esdb-gater.yaml \
  -f ex-esdb-gater-override.yaml \
  --profile gater \
  -p gater \
  up \
  --remove-orphans \
  --build \
  -d
