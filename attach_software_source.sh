#!/bin/bash
# Attach child software source to all instances in a managed instance group.
# 
# If FLAG_DETACH_CURRENT_SOURCES enabled: Detach all currently attached sources before attaching new sources. (Default true)

[ -z "$2" ] && echo "usage: ${0} source-name target-group-name" && exit

SOURCE_NAME=$1
TARGET_GROUP_NAME=$2

# set this flag to detach all current child software sources and attach only
# the child software source passed as argument
FLAG_DETACH_CURRENT_SOURCES=true

source ./osms_config.sh
COMPARTMENT_OCID=$OSMS_COMPARTMENT_OCID

TARGET_SOURCE_OCID=`oci os-management software-source list --compartment-id $COMPARTMENT_OCID --query 'data[?"display-name"==\`'${SOURCE_NAME}'\`].id | [0]' | jq . -r`
TARGET_GROUP_OCID=`oci os-management managed-instance-group list --compartment-id $COMPARTMENT_OCID --query 'data[? "display-name" == \`'$TARGET_GROUP_NAME'\`].id' | jq .[0] -r`
TARGET_GROUP_MEMBERS=`oci os-management managed-instance-group get --managed-instance-group-id $TARGET_GROUP_OCID --query 'data."managed-instances"[].id' | jq .[] -r`

for TARGET_INSTANCE in ${TARGET_GROUP_MEMBERS//\\n/ }
do
   echo "updating $TARGET_INSTANCE"

   if [ "$FLAG_DETACH_CURRENT_SOURCES" = true ]; then
     CURRENT_SOURCES=`oci os-management managed-instance get --managed-instance-id $TARGET_INSTANCE --query 'data."child-software-sources"[].id' | jq .[] -r`
     for CURRENT_SOURCE in ${CURRENT_SOURCES//\\n/ }
     do
       oci os-management managed-instance detach-child --managed-instance-id $TARGET_INSTANCE --software-source-id $CURRENT_SOURCE
     done 
  fi

     oci os-management managed-instance attach-child --managed-instance-id $TARGET_INSTANCE --software-source-id $TARGET_SOURCE_OCID

done



