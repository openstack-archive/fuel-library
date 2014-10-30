# == Class: swift::test_file
#
# Deploys a file that can be used to verify your swift installation.
#
# === Parameters
#
# [*password*]
#    password used with tenant/user combination against auth_server. Required.
# [*auth_server*]
#    server hosting keystone. Optional. Defaults to 127.0.0.1.
# [*tenant*]
#    tenant used for authentication (required for retrieval of catalog). Optional. Defaults to openstack.
# [*user*]
#    authenticated user. Optional. Defaults to 'admin'.
#
# === Examples
#
#  class { 'swift::test_file':
#    auth_server => '172.16.0.25',
#    tenant      => 'services',
#    user        => 'swift',
#    password    => 'admin_password',
#  }
#
# === Authors
#
# Dan Bode <bodepd@gmail.com>
#
# === Copyright
#
# Copyright 2011 PuppetLabs.
#
class swift::test_file (
  $password,
  $auth_server = '127.0.0.1',
  $tenant      = 'openstack',
  $user        = 'admin'
) {
  file { '/tmp/swift_test_file.rb':
    mode    => '0755',
    content => template('swift/swift_keystone_test.erb')
  }
}
