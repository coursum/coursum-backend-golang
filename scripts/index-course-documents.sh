#!/usr/bin/env bash
set -e
source .env

filepath="database/syllabus-json-files"
requestfile="request"
responsefile="response.json"

files=$(ls ${filepath})

numOfCourseFiles=$(echo ${files} | tr ' ' '\n' | wc -l | sed 's/ *//g')
echo "There are ${numOfCourseFiles} course files in total"

echo "Removing request file if exist"
if [[ -e ${requestfile} ]]; then
  rm ${requestfile}
fi

echo "Generating bulk request file..."
for file in ${files}; do
  echo "{ \"create\" : { \"_index\" : \"${ELASTICSEARCH_DEFAULT_INDEX}\", \"_id\" : \"${file%.json}\" } }" >> ${requestfile}
  echo $(cat ${filepath}/${file}) >> ${requestfile}
done

echo "Successfully generated bulk request file"

echo "Removing response file if exist"
if [[ -e ${responsefile} ]]; then
  rm ${responsefile}
fi

echo "Performing bulk request & Generating response file..."
curl -s -H "Content-Type: application/x-ndjson" -XPOST "${ELASTICSEARCH_USERINFO}@localhost:9200/_bulk?pretty=true" --data-binary "@${requestfile}" > "${responsefile}"

echo "Bulk request finished"
echo "Indexing finished"
echo "Please remove ${requestfile} & ${responsefile} if no longer necessary"
