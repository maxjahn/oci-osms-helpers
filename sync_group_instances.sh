#!/bin/bash
# Synchronize packages for instances in a managed instance group
# (1) Install all available updates available for the group, i.e. from all sources attached to the instances
# (2) Install packages available in source passed as argument
# (3) If FLAG_REMOVE_PACKAGES enabled: Remove packages from instances that are not presend in source passed as argument. (Default false)
#
# This script can take some time as fetching installed packages and installing packages
# is a very slow process

[ -z "$2" ] && echo "usage: ${0} source-name target-group-name" && exit

SOURCE_NAME=$1
TARGET_GROUP_NAME=$2

# set this flag to enable removing packages that are not included in the target source
# this will fail for many core packages that need to be present
FLAG_REMOVE_PACKAGES=false

[ ! -d "current" ] && echo "creating current directory" && mkdir current

source ./osms_config.sh
COMPARTMENT_OCID=$OSMS_COMPARTMENT_OCID

TARGET_SOURCE_OCID=`oci os-management software-source list --compartment-id $COMPARTMENT_OCID --query 'data[?"display-name"==\`'${SOURCE_NAME}'\`].id | [0]' | jq . -r`
TARGET_GROUP_OCID=`oci os-management managed-instance-group list --compartment-id $COMPARTMENT_OCID --query 'data[? "display-name" == \`'$TARGET_GROUP_NAME'\`].id' | jq .[0] -r`
TARGET_GROUP_MEMBERS=`oci os-management managed-instance-group get --managed-instance-group-id $TARGET_GROUP_OCID --query 'data."managed-instances"[].id' | jq .[] -r`

# for synchronous mode use SUCCEEDED, for asynchronous mode use ACCEPTED
WAIT_FOR_STATE="SUCCEEDED"

TARGET_PACKAGES=`oci os-management software-source list-packages --software-source-id $TARGET_SOURCE_OCID --all --query 'data[].name' `
echo $TARGET_PACKAGES > current/${SOURCE_NAME}_target_packages.json

for TARGET_INSTANCE in ${TARGET_GROUP_MEMBERS//\\n/ }
do
   echo "installing all updates for $TARGET_INSTANCE"
   oci os-management managed-instance install-all-updates --wait-for-state $WAIT_FOR_STATE --wait-for-state FAILED --managed-instance-id $TARGET_INSTANCE --query 'data[].resources[].name'

   echo "fetching installed packages."
   INSTANCE_PACKAGES=`oci os-management managed-instance list-installed-packages --managed-instance-id $TARGET_INSTANCE --all --query 'data [?"software-sources"] | [*].name'`
   echo $INSTANCE_PACKAGES > current/${TARGET_INSTANCE}_packages.json

   if [ "$FLAG_REMOVE_PACKAGES" = true ]; then
      echo
      echo "removing packages not included in target source:"
      REMOVABLE_PACKAGES=`jq -n --argfile a current/${SOURCE_NAME}_target_packages.json  --argfile b current/${TARGET_INSTANCE}_packages.json '{"target":$a, "instance":$b} | .instance-.target | .[]' -r`
      
      for PACKAGE in ${REMOVABLE_PACKAGES//\\n/ }
      do
         echo $PACKAGE
         oci os-management managed-instance remove-package --package-name $PACKAGE --wait-for-state $WAIT_FOR_STATE --wait-for-state FAILED --managed-instance-id $TARGET_INSTANCE --query 'data.status'
         echo
      done

      echo "fetching installed packages again."
      INSTANCE_PACKAGES=`oci os-management managed-instance list-installed-packages --managed-instance-id $TARGET_INSTANCE --all --query 'data [?"software-sources"] | [*].name'`
      echo $INSTANCE_PACKAGES > current/${TARGET_INSTANCE}_packages.json
   fi

   echo
   echo "installing missing packages:"
   AVAILABLE_PACKAGES=`jq -n --argfile a current/${SOURCE_NAME}_target_packages.json  --argfile b current/${TARGET_INSTANCE}_packages.json '{"target":$a, "instance":$b} | .target-.instance | .[]' -r`  

   for PACKAGE in ${AVAILABLE_PACKAGES//\\n/ }
   do
      echo $PACKAGE
      oci os-management managed-instance install-package --package-name $PACKAGE --wait-for-state $WAIT_FOR_STATE --wait-for-state FAILED  --managed-instance-id $TARGET_INSTANCE --query 'data.status'
      echo
   done

   echo

done

