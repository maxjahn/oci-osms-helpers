#!/bin/bash
# Create a new child software source from a template instance
# This will take all installed packages on the template instance and create a 
# json document from it. This json document can be used to create a new source.
# Use version control on the document to keep track of history.

[ -z "$2" ] && echo "usage: ${0} template-instance-ocid custom-software-source-name" && exit

source ./osms_config.sh

COMPARTMENT_OCID=$OSMS_COMPARTMENT_OCID

TEMPLATE_INSTANCE_OCID=$1
SOURCE_NAME=$2

[ ! -d "sources" ] && echo "creating sources directory" && mkdir sources

exit

# create package list
PACKAGE_LIST=`oci os-management managed-instance list-installed-packages --managed-instance-id $TEMPLATE_INSTANCE_OCID --all --query 'data [?"software-sources"] | [*].name'`
echo $PACKAGE_LIST > sources/${SOURCE_NAME}_packages.json

# create child software source
SOURCE_OCID=`oci os-management software-source create --compartment-id $COMPARTMENT_OCID --parent-id $PARENT_SOURCE_OCID --display-name $SOURCE_NAME --arch-type X86_64 --query "data.id" | jq . -r`
oci os-management software-source add-packages --software-source-id ${SOURCE_OCID} --package-names file://sources/${SOURCE_NAME}_packages.json 





