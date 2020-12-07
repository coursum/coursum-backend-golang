#!/usr/bin/env bash
set -e
source .env

echo "Defining component template"
curl -X PUT "${ELASTICSEARCH_USERINFO}@localhost:9200/_component_template/use_kuromoji_normalize_analyzer?pretty" -H 'Content-Type: application/json' -d'
{
  "template": {
    "settings": {
      "analysis": {
        "analyzer": {
          "default": {
            "char_filter": [
              "icu_normalizer"
            ],
            "tokenizer": "kuromoji_tokenizer",
            "filter": [
              "kuromoji_baseform",
              "kuromoji_part_of_speech",
              "cjk_width",
              "ja_stop",
              "kuromoji_stemmer",
              "lowercase"
            ]
          }
        }
      }
    }
  }
}
'

echo "Defining index template"
curl -X PUT "${ELASTICSEARCH_USERINFO}@localhost:9200/_index_template/template_1?pretty" -H 'Content-Type: application/json' -d"
{
  \"index_patterns\": [\"${ELASTICSEARCH_DEFAULT_INDEX}\"],
  \"version\": 1,
  \"composed_of\": [\"use_kuromoji_normalize_analyzer\"],
  \"_meta\": {
    \"description\": \"Template for index ${ELASTICSEARCH_DEFAULT_INDEX}\"
  }
}
"
