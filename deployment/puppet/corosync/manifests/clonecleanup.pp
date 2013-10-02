# == Class: clonecorosync::cleanup
#
# Include this class to cleanup the corosync resource when there are changes in
# any of the native cs_* types. Useful for multi-node provisioning when the
# nodes are not always in a stable state after provisioning.
#
# === Examples
#
# clone mysql-galera cleanup corosync after making cluster configuration changes:
#
#   include corosync::clonecleanup
#
# === Copyright
#
# Copyright 2012 Puppet Labs, LLC.
#
define corosync::clonecleanup () {
  Cs_resource <| name == $name |> ~> Exec["crm resource clonecleanup $name"]

  exec { "crm resource clonecleanup $name":
    command     => "bash -c \"(sleep 10 && crm_resource --resource clone_${name}  --cleanup) || :\"",
    path        => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    returns     => [0,""],
    refreshonly => true,
    timeout     => 600,
  }
}  
