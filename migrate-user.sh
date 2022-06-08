#!/usr/bin/env bash
set -e
###################################################################
# Test for for the presents of the utilities needed by this script
###################################################################
function test_env {
  if (! command -v yq &> /dev/null) ||
     (! command -v psql &> /dev/null) ||
     (! command -v http &> /dev/null)
  then
      echo "The following commands are require to run this script:"
      echo "  yq - https://mikefarah.gitbook.io/yq/"
      echo "  psql - https://www.postgresql.org/download/"
      echo "  http - https://httpie.io/download"
      exit
  fi
}
test_env

# If you have an Okta Org already run `okta login` otherwise
# run `okta register` to create a new one
OKTA_CONFIG="/Users/bdemers/.okta/okta.yaml"
OKTA_ORG=$(yq '.okta.client.orgUrl' ${OKTA_CONFIG})
OKTA_TOKEN=$(yq '.okta.client.token' ${OKTA_CONFIG})

# The example DB is in a docker container, use `docker compose up` to start the DB
DOCKER_COMPOSE=./docker-compose.yml
POSTGRES_DB=$(yq '.services.db.environment.POSTGRES_DB' ${DOCKER_COMPOSE})
POSTGRES_USER=$(yq '.services.db.environment.POSTGRES_USER' ${DOCKER_COMPOSE})
export PGPASSWORD=$(yq '.services.db.environment.POSTGRES_PASSWORD' ${DOCKER_COMPOSE})


function cleanup {
  http POST "${OKTA_ORG}/api/v1/users/admin@example.com/lifecycle/deactivate" \
    "Authorization: SSWS ${OKTA_TOKEN}"
  http DELETE "${OKTA_ORG}/api/v1/users/admin@example.com" \
    "Authorization: SSWS ${OKTA_TOKEN}"

  http POST "${OKTA_ORG}/api/v1/users/user1@example.com/lifecycle/deactivate" \
    "Authorization: SSWS ${OKTA_TOKEN}"
  http DELETE "${OKTA_ORG}/api/v1/users/user1@example.com" \
    "Authorization: SSWS ${OKTA_TOKEN}"

  http POST "${OKTA_ORG}/api/v1/users/user2@example.com/lifecycle/deactivate" \
    "Authorization: SSWS ${OKTA_TOKEN}"
  http DELETE "${OKTA_ORG}/api/v1/users/user2@example.com" \
    "Authorization: SSWS ${OKTA_TOKEN}"
}
cleanup


###################################################################
# Splits a _standard_ bcrypt formatted into comma seperated string.
# and returns it in the format of "[cost] [salt] [hash]"
###################################################################
function hash_parts {
  echo ${pw_hash} | awk '{split($0, parts, "$"); print parts[3] " " substr(parts[4],0,22) " " substr(parts[4],23)}'
}

###################################################################
# Imports a user with attributes and an existing password hash.
# Usage: import_user_with_pw [email] [pw_hash] [fname] [lname] [phone]
###################################################################
function import_user_with_pw {
  local email=${1}
  local pw_hash=${2}
  local fname=${3}
  local lname=${4}
  local phone=${5}
  # split up the hash string into it's parts
  local pw_hash_parts=($(hash_parts ${pw_hash}))

  echo "Importing User with hash:"
  echo "  email: ${email}"
  echo "  fname:  ${fname}"
  echo "  lname:  ${lname}"
  echo "  phone:  ${phone}"
  echo

  # Call the Okta Users API and create a user with an existing hash
  http --ignore-stdin --check-status \
    "${OKTA_ORG}/api/v1/users" \
    "Authorization: SSWS ${OKTA_TOKEN}" \
    profile[firstName]="${fname}" \
    profile[lastName]="${lname}" \
    profile[email]="${email}" \
    profile[login]="${email}" \
    profile[mobilePhone]="${phone}" \
    credentials[password][hash][algorithm]=BCRYPT \
    credentials[password][hash][workFactor]="${pw_hash_parts[0]}" \
    credentials[password][hash][salt]="${pw_hash_parts[1]}" \
    credentials[password][hash][value]="${pw_hash_parts[2]}"

}

# Query the 'users' table of the database for records that have a password hash that
# can be imported into Okta
#psql --host localhost \
#     --dbname ${POSTGRES_DB} \
#     --username ${POSTGRES_USER} \
#     --tuples-only \
#     --no-align \
#     --field-separator ' ' \
#     --quiet \
#     -c "SELECT username, password, first_name, last_name, phone FROM users WHERE enabled=true AND password LIKE '{bcrypt}%';" \
#  | while read username pw_hash first_name last_name phone ; do
#     import_user_with_pw "${username}" "${pw_hash}" "${first_name}" "${last_name}" "${phone}"
#  done



###################################################################
# Imports a user with attributes will call password hook the first
# time the user signs in.
# Usage: import_user_with_hook [email] [fname] [lname] [phone]
###################################################################
function import_user_with_hook {
  local email=${1}
  local fname=${2}
  local lname=${3}
  local phone=${4}

  echo "Importing User with hook:"
  echo "  email: ${email}"
  echo "  fname:  ${fname}"
  echo "  lname:  ${lname}"
  echo "  phone:  ${phone}"
  echo

  # Call the Okta Users API and create a user with an existing hash
  http --ignore-stdin --check-status \
    "${OKTA_ORG}/api/v1/users" \
    "Authorization: SSWS ${OKTA_TOKEN}" \
    profile[firstName]="${fname}" \
    profile[lastName]="${lname}" \
    profile[email]="${email}" \
    profile[login]="${email}" \
    profile[mobilePhone]="${phone}" \
    credentials[password][hook][type]=default

}

# Query the 'users' table of the database for records that do NOT have a supported hash type
psql --host localhost \
     --dbname ${POSTGRES_DB} \
     --username ${POSTGRES_USER} \
     --tuples-only \
     --no-align \
     --field-separator ' ' \
     --quiet \
     -c "SELECT username, first_name, last_name, phone FROM users WHERE enabled=true AND password NOT LIKE '{bcrypt}%';" \
  | while read username first_name last_name phone ; do
     import_user_with_hook "${username}" "${first_name}" "${last_name}" "${phone}"
  done