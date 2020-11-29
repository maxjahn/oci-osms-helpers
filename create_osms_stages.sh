#!/bin/bash
# Basic initialization for OSMS stages
# (1) Create empty parent software
# (2) Create empty managed instance groups for stages
# (3) Write a config file to use in other scripts

# set these variables to match your target environment
COMPARTMENT_OCID=ocid1.compartment.....
STAGES=(test prod)
PARENT_SOURCE_NAME="patch-parent-source"

echo "OSMS_COMPARTMENT_OCID=$COMPARTMENT_OCID" > osms_config.sh
echo "STAGES=(${STAGES[@]})" >> osms_config.sh

# create parent source
SOURCE_OCID=`oci os-management software-source create --compartment-id $COMPARTMENT_OCID --display-name $PARENT_SOURCE_NAME --arch-type X86_64 --query "data.id" `
echo "PARENT_SOURCE_OCID=$SOURCE_OCID" >> osms_config.sh

# create managed instance groups
for stage in "${STAGES[@]}" 
do 
  GROUP_OCID=`oci os-management managed-instance-group create --compartment-id $COMPARTMENT_OCID --display-name osms-${stage} --query "data.id"`
  echo "MANAGED_GROUP_${stage}=$GROUP_OCID" >> osms_config.sh
done



