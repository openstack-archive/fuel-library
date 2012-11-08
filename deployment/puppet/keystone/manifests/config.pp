# The keystone::config defined resource type is used
# to model the keystone config file as fragments.
#
# File Fragments are a common Puppet pattern where Puppet creates its
# own .d directory for a certain config file so that independently configuration
# sections can be decoupled and managed independently.
#
# The resulting config file is constructed by concatenating all of these
# fragments into the desired configuration file.
#
# == Parameters
#
#
# [*parameters*]
#
#   [config] Hash of parameters that can be used to create the config section.
#     This hash can be accessed from within a template. Optional. Defaults to {}
#
#   [content] Content used to create the file fragment. Optional. Defaults to
#     template("keystone/${name}.erb"
#
#   [order] Used to determine how to order fragments in the resulting file. Accepts
#   an integer. Optional. Defaults to undef.
#
# == Dependencies
#
#   from Class['keystone']
#     Requires: Concat['/etc/keystone/keystone.conf'] which models the concatenation
#       concat { '/etc/keystone/keystone.conf':}
#     Requires: Class['concat::setup'] which sets up the fragment directories
#
# == Examples
#
#  # the following will use the template in templates/mysql.erb
#  keystone::config { 'mysql':
#    config => {
#      user          => $user,
#      password      => $password,
#      host          => $host,
#      dbname        => $dbname,
#      idle_timeout  => $idle_timeout,
#      min_pool_size => $min_pool_size,
#      max_pool_size => $max_pool_size,
#      pool_timeout  => $pool_timeout
#    },
#    order  => '02',
#   }
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#
define keystone::config(
  $config    = {},
  $content   = template("keystone/${name}.erb"),
  $order     = undef
) {
  concat::fragment { "kestone-${name}":
    target  => '/etc/keystone/keystone.conf',
    content => $content,
    order   => $order,
  }
}
