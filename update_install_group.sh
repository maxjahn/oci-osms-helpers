#!/bin/bash
# Synchronize packages in a managed instance group
# (1) Install all available updates available for the group, i.e. from all sources attached to the instances
# (2) Install packages available in source passed as argument
#
# Caution: Unlike the script for individual instances, this one will not remove any packages

[ -z "$2" ] && echo "usage: ${0} source-name target-group-name" && exit

SOURCE_NAME=$1
TARGET_GROUP_NAME=$2

[ ! -d "current" ] && echo "creating current directory" && mkdir current

source ./osms_config.sh
COMPARTMENT_OCID=$OSMS_COMPARTMENT_OCID

CURR_TIMESTAMP=`date "+%Y%m%d_%H%M%S"`
TARGET_GROUP_OCID=`oci os-management managed-instance-group list --compartment-id $COMPARTMENT_OCID --query 'data[? "display-name" == \`'$TARGET_GROUP_NAME'\`].id' | jq .[0] -r`
TARGET_SOURCE_OCID=`oci os-management software-source list --compartment-id $COMPARTMENT_OCID --query 'data[?"display-name"==\`'${SOURCE_NAME}'\`].id | [0]' | jq . -r`
TARGET_PACKAGES=`oci os-management software-source list-packages --software-source-id $TARGET_SOURCE_OCID --all --query 'data[*].{name: name}'`
echo $TARGET_PACKAGES > current/${SOURCE_NAME}_target_packages.json

echo "Scheduling job UPDATEALL"
oci os-management scheduled-job create --compartment-id $COMPARTMENT_OCID \
--display-name "${SOURCE_NAME} Update All ${CURR_TIMESTAMP}" --operation-type UPDATEALL --update-type ALL \
--schedule-type ONETIME --time-next-execution `date -v+5M +%s` \
--managed-instance-groups "[{ \"displayName\": \"${TARGET_GROUP_NAME}\",  \"id\": \"${TARGET_GROUP_OCID}\"}]" \
--wait-for-state ACTIVE --wait-for-state FAILED --query 'data."lifecycle-state"'

echo "Scheduling job INSTALL"
oci os-management scheduled-job create --compartment-id $COMPARTMENT_OCID \
--display-name "${SOURCE_NAME} Install ${CURR_TIMESTAMP}" --operation-type INSTALL \
--schedule-type ONETIME --time-next-execution `date -v+10M +%s` \
--managed-instance-groups "[{ \"displayName\": \"${TARGET_GROUP_NAME}\",  \"id\": \"${TARGET_GROUP_OCID}\"}]" \
--package-names file://current/${SOURCE_NAME}_target_packages.json \
--wait-for-state ACTIVE --wait-for-state FAILED --query 'data."lifecycle-state"'

