#!/bin/bash
# Adds an instance to a managed instance group and replaces current parent source 
# with target parent source
# 
# (1) Attach instance to target managed instance group
# (2) Detach current parent source from instance
# (3) Attach target parent source to instance

[ -z "$2" ] && echo "usage: ${0} target-group-name instance-ocid" && exit

source ./osms_config.sh

COMPARTMENT_OCID=$OSMS_COMPARTMENT_OCID

TARGET_GROUP=$1
TARGET_INSTANCE_OCID=$2

TARGET_GROUP_OCID=`oci os-management managed-instance-group list --compartment-id $COMPARTMENT_OCID --query 'data[? "display-name" == \`'$TARGET_GROUP'\`].id' | jq .[0] -r`
oci os-management managed-instance-group attach --managed-instance-group-id $TARGET_GROUP_OCID  --managed-instance-id $TARGET_INSTANCE_OCID

CURRENT_PARENT_SOURCE_OCID=`oci os-management managed-instance get --managed-instance-id $TARGET_INSTANCE_OCID --query 'data."parent-software-source".id' | jq . -r`
oci os-management managed-instance detach-parent --managed-instance-id $TARGET_INSTANCE_OCID --software-source-id $CURRENT_PARENT_SOURCE_OCID
oci os-management managed-instance attach-parent --managed-instance-id $TARGET_INSTANCE_OCID --software-source-id $PARENT_SOURCE_OCID


