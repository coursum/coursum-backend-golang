#!/usr/bin/env bash
set -e
source .env

echo "Deleting course index"
curl -X DELETE "${ELASTICSEARCH_USERINFO}@localhost:9200/${ELASTICSEARCH_DEFAULT_INDEX}?pretty=true"
