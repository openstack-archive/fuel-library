# == Class: corosync::reprobe
#
# Include this class to reprobe the corosync cluster when there are changes in
# any of the native cs_* types. Useful for multi-node provisioning when the
# nodes are not always in a stable state after provisioning.
#
# === Examples
#
# Reprobe corosync after making cluster configuration changes:
#
#   include corosync::reprobe
#
# === Copyright
#
# Copyright 2012 Puppet Labs, LLC.
#
class corosync::reprobe {
  exec { 'crm resource reprobe':
    path        => ['/bin','/usr/bin','/sbin','/usr/sbin'],
    refreshonly => true,
  }
  Cs_primitive <| |> {
    notify => Exec['crm resource reprobe'],
  }
  Cs_colocation <| |> {
    notify => Exec['crm resource reprobe'],
  }
  Cs_order <| |> {
    notify => Exec['crm resource reprobe'],
  }
  Cs_group <| |> {
    notify => Exec['crm resource reprobe'],
  }
  Cs_commit <| |> {
    notify => Exec['crm resource reprobe'],
  }
}
