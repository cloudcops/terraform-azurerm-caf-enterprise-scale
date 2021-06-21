#!/usr/bin/env bash
set -e

#
# Shell Script
# - OPA Run Tests
#
# # Parameters
TF_PLAN_JSON="terraform-plan-$TF_VERSION-$TF_AZ_VERSION"

# # # Store data temporarily
TEMP_FILE_01=$(mktemp).json
TEMP_FILE_02=$(mktemp).json

# # # Update the planned_values.json with the latest parameters
echo "==> Update planned values..."
cd ../deployment ###../opa/policy
jq '(.. | strings) |= gsub("root-id-1"; "'"$TF_ROOT_ID_1"'")' planned_values.json >"$TEMP_FILE_01"
jq '(.. | strings) |= gsub("root-id-2"; "'"$TF_ROOT_ID_2"'")' "$TEMP_FILE_01" >"$TEMP_FILE_02"
jq '(.. | strings) |= gsub("root-id-3"; "'"$TF_ROOT_ID_3"'")' "$TEMP_FILE_02" >"$TEMP_FILE_01"
jq '(.. | strings) |= gsub("root-name"; "ES-'"$TF_VERSION"'-'"$TF_AZ_VERSION"'")' "$TEMP_FILE_01" >"$TEMP_FILE_02"
jq '(.. | strings) |= gsub("eastus"; "'"$LOCATION"'")' "$TEMP_FILE_02" >"$TF_PLAN_JSON"_updated_planned_values.json

echo "==> Module Location - $LOCATION"
echo "==> Azure {TF_ROOT_ID_1} - ${TF_ROOT_ID_1}"
echo "==> Azure TF_ROOT_ID_1 - $TF_ROOT_ID_1"

wait

echo "==> Converting to yaml..."
yq <"$TF_PLAN_JSON"_updated_planned_values.json e -P - >../opa/policy/"$TF_PLAN_JSON"_updated_planned_values.yml

wait

echo "==> Check yaml for errors..."
yamllint -d relaxed ../opa/policy/"$TF_PLAN_JSON"_updated_planned_values.yml

echo "==> Running conftest..."
cd ../deployment
conftest test "$TF_PLAN_JSON".json -p ../opa/policy -d ../opa/policy/"$TF_PLAN_JSON"_updated_planned_values.yml
