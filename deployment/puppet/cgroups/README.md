CGroups
=======

This puppet module is for configuring Control Groups on the nodes.
At the moment, it supports Ubuntu 14.04+ only.


## Classes

### Initialization

Place this module at /etc/puppet/modules/cgroups or in the directory where
your puppet modules are stored.

The 'cgroups' class has the following parameters and default values:

    class { 'cgroups':
      cgroups_set => {},
      packages    => [cgroup-bin, libcgroup1, cgroup-upstart],
    }

* *cgroups_set* - user settings of Control Groups defined in the hash
 format.
* *packages* - list of necessary packages for cgroups.

By default cgroups is disabled. It will be enabled, if user specify limits
for cluster via API/CLI.


### Service

This class contains all necessary services for work of cgroups.

Service 'cgroup-lite' mounts cgroups at the "/sys/fs/cgroups" when starts
and unmounts them when stops.

Service 'cgconfigparser' parses /etc/cgconfig.conf and sets up cgroups in the
 /sys/fs/cgroups every time when starts.

Service 'cgrulesengd' is a CGroups Rules Engine Daemon. This daemon
distributes processes to control groups. When any process changes its
effective UID or GID, cgrulesengd inspects the list of rules loaded from the
/etc/cgrules.conf file and moves the process to the appropriate control group.

Service 'cgclassify' moves processes defined by the list of processes to given
 control groups.

The 'cgroups::service' class has only the 'cgroups_set' parameter.

## Usage

For activating cgroup user should add 'cgroup' section into cluster's settings
file via CLI. For example:

  cgroups:
    metadata:
      group: general
      label: Cgroups configuration
      weight: 90
      restrictions:
        - condition: "true"
        action: "hide"
    keystone:
      label: keystone
      type:  text
      value: {"cpu":{"cpu.shares":70}}

Format of relative expressions is (for example, memory limits):

  %percentage_value, minimal_value, maximum_value

It means that:

    * percentage value(% of total memory) will be calculated and
      then clamped to keep value within the range( percentage value
      will be used if total node's RAM lower than minimal range value)
    * minimal value will be taken if node's RAM lower than minimal
      value
    * maximum value will be taken if node's RAM upper than maximum
      value

Example:

  %20, 2G, 20G


## Documentation

Official documentation for CGroups can be found in the
https://www.kernel.org/doc/Documentation/cgroup-v1/cgroups.txt
