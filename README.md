# Helper Scripts for Oracle Cloud (OCI) OS Management

This is a collection of demo helper scripts for using OCI OS Management. These scripts will enable a simple process of moving defined patch/update packages through several stages for testing up to production environment. 

The typical process would start with installling updates and packages on a templace instance. Then a list of installed packages are exported and used to create a custom software source. This custom child software source can be attached to a managed instance group, so updates and packages can be installed.

### Prepare Environment

#### create_osms_stages.sh 
Basic initialization for OSMS stages. This will

1. Create empty parent software,
1. Create empty managed instance groups for stages, and
1. Write a config file to use in other scripts

#### attach_group_instance.sh source-name target-group-name"

Attaches child software source to all instances in a managed instance group.
 
If FLAG_DETACH_CURRENT_SOURCES enabled: Detach all currently attached sources before attaching new sources. (Default true)

### Creating and Attaching Software Sources

#### create_child_software_source.sh template-instance-ocid custom-software-source-name

Create a new child software source from a template instance.
This will take all installed packages on the template instance and create a json document from it. This json document can be used to create a new source.

Use version control on the document to keep track of history.

#### attach_software_source.sh source-name target-group-name

Attach child software source to all instances in a managed instance group.

If FLAG_DETACH_CURRENT_SOURCES enabled: Detach all currently attached sources before attaching new sources. (Default true)


### Check Deviations from Target Source

#### check_deviations.sh source-name target-group-name

Check deviations of packages installed on instances in a group from target configuration/source. Steps include identifying:

1. Packages included in source but no installed on instance, and
1. Packages installed in instance but not included in source

The packages installed on each instance and packages included in the target software source are written as json documents to directory current.

### Synchronize Packages

#### sync_group_instances.sh source-name target-group-name

Synchronize packages for a managed instance group, including the steps: 

1. Installing all available updates available for the group, i.e. from all sources attached to the instances,
1. Installing packages available in source passed as argument, and
1. If FLAG_REMOVE_PACKAGES enabled: Remove packages from instances that are not presend in source passed as argument. (Default false)

This script can take some time as fetching installed packages and installing packages is a very slow process.






