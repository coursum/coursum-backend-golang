#!/usr/bin/env bash

reset="\033[0m"
error=$(echo -e "\033[31mError${reset}")

function invalid_option() {
  echo "${error}: invalid option: ${1}"
  exit 1
}

while [[ ${#} > 0 ]]; do
  case ${1} in
    -n|--dry-run)
      dry_run="true"
    ;;
    -*)
      invalid_option ${1}
    ;;
    *)

    ;;
  esac
  shift
done

source ./.env

files=(
  ".env"
  "configs/logstash/driver"
  "configs/postgresql/init-database"
)

for file in ${files[@]}; do
  command="scp -i ${IDENTITY_FILE} -pr ./${file} ${SERVER_USER}@${SERVER_URI}:~/${COMPOSE_PROJECT_NAME}/${file}"

  [[ ${dry_run} == "true" ]] && echo ${command} || eval ${command}
done
