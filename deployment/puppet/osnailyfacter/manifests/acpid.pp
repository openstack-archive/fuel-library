# == Class: osnailyfacter::acpid
#
# Allow to install and configure acpid.
#
# === Parameters
#
# [*service_enabled*]
#   Enable acpid service, default to true.
#
# [*service_state*]
#   Start acpid service, default to running.
#
class osnailyfacter::acpid (
  $service_enabled = true,
  $service_state   = 'running',
  ){

  package { 'acpid':
    ensure => 'installed',
  } ->

  service { 'acpid':
    ensure => $service_state,
    enable => $service_enabled,
  }
}

