# == Class: openstack::nova::security
#
# This class implements basic nova security groups.
#
# === Examples
#
#  class { 'openstack::nova::security': }
#
class openstack::nova::security (
  $auth_url,
  $auth_username = 'admin',
  $auth_password = 'admin',
  $auth_tenant   = 'admin',
) {

  Nova_secgroup {
    auth_username => $auth_username,
    auth_password => $auth_password,
    auth_tenant => $auth_tenant,
    auth_url => $auth_url,
  }

  Nova_secrule {
    auth_username => $auth_username,
    auth_password => $auth_password,
    auth_tenant => $auth_tenant,
    auth_url => $auth_url,
  }

# Group for HTTP traffic
  nova_secgroup { 'global_http':
    ensure => present,
    description => 'Allow HTTP traffic',
  } ->

  nova_secrule { 'http_01':
    ensure => present,
    ip_protocol => 'tcp',
    from_port => 80,
    to_port => 80,
    ip_range => '0.0.0.0/0',
    security_group => 'global_http'
  } ->

  nova_secrule { 'http_02':
    ensure => present,
    ip_protocol => 'tcp',
    from_port => 443,
    to_port => 443,
    ip_range => '0.0.0.0/0',
    security_group => 'global_http'
  }


# Group for ssh traffic
  nova_secgroup { 'global_ssh':
    ensure => present,
    description => 'Allow SSH traffic',
  } ->

  nova_secrule { 'ssh_01':
    ensure => present,
    ip_protocol => 'tcp',
    from_port => 22,
    to_port => 22,
    ip_range => '0.0.0.0/0',
    security_group => 'global_ssh'
  }


# Group for allow all
  nova_secgroup { 'allow_all':
    ensure => present,
    description => 'Allow all traffic',
  } ->

  nova_secrule { 'all_01':
    ensure => present,
    ip_protocol => 'tcp',
    from_port => 1,
    to_port => 65535,
    ip_range => '0.0.0.0/0',
    security_group => 'allow_all'
  } ->

  nova_secrule { 'all_02':
    ensure => present,
    ip_protocol => 'udp',
    from_port => 1,
    to_port => 65535,
    ip_range => '0.0.0.0/0',
    security_group => 'allow_all'
  }

}
