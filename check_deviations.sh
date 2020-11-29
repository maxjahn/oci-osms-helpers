#!/bin/bash
# Check deviations of packages installed on instances in a group from target configuration/source
# (1) Packages included in source but no installed on instance
# (2) Packages installed in instance but not included in source
#
# The packages installed on each instance and packages included in the target software source
# are written as json documents to directory current.

[ -z "$2" ] && echo "usage: ${0} source-name target-group-name" && exit

SOURCE_NAME=$1
TARGET_GROUP_NAME=$2

[ ! -d "current" ] && echo "creating current directory" && mkdir current

source ./osms_config.sh
COMPARTMENT_OCID=$OSMS_COMPARTMENT_OCID

TARGET_SOURCE_OCID=`oci os-management software-source list --compartment-id $COMPARTMENT_OCID --query 'data[?"display-name"==\`'${SOURCE_NAME}'\`].id | [0]' | jq . -r`
TARGET_GROUP_OCID=`oci os-management managed-instance-group list --compartment-id $COMPARTMENT_OCID --query 'data[? "display-name" == \`'$TARGET_GROUP_NAME'\`].id' | jq .[0] -r`
TARGET_GROUP_MEMBERS=`oci os-management managed-instance-group get --managed-instance-group-id $TARGET_GROUP_OCID --query 'data."managed-instances"[].id' | jq .[] -r`

TARGET_PACKAGES=`oci os-management software-source list-packages --software-source-id $TARGET_SOURCE_OCID --all --query 'data[].name' `
echo $TARGET_PACKAGES > current/${SOURCE_NAME}_target_packages.json

for TARGET_INSTANCE in ${TARGET_GROUP_MEMBERS//\\n/ }
do
   echo "checking $TARGET_INSTANCE"
   INSTANCE_PACKAGES=`oci os-management managed-instance list-installed-packages --managed-instance-id $TARGET_INSTANCE --all --query 'data [?"software-sources"] | [*].name'`
   echo $INSTANCE_PACKAGES > current/${TARGET_INSTANCE}_packages.json
   echo "packages not installed on $TARGET_INSTANCE"
   jq -n --argfile a current/${SOURCE_NAME}_target_packages.json  --argfile b current/${TARGET_INSTANCE}_packages.json '{"target":$a, "instance":$b} | .target-.instance'
   echo
   echo "packages not included in target source"
   jq -n --argfile a current/${SOURCE_NAME}_target_packages.json  --argfile b current/${TARGET_INSTANCE}_packages.json '{"target":$a, "instance":$b} | .instance-.target'

done

