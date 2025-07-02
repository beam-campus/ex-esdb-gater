#! /bin/bash

## CLEAR ALL DATA
# echo "Clearing all data"
# sudo rm -rf /volume

docker-compose -f livebook.yml \
  -f excalidraw.yml \
  -f networks.yml \
  -p tools \
  --profile tools \
  down
