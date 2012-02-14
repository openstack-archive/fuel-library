#
# This file contains an example set of configuration that can be applied
# to nodes before swift is installed on them.
#
# This file is used to set up the basic environment that is used for
# testing swift deployments.
#
# use the trunk repo for swift packages
class { 'swift::repo::trunk':}

#
# install the class apt and use 10.0.2.2:3128 as a proxy
#
class { 'apt':
  proxy_host   => '10.0.2.2',
  proxy_port   => '3128',
  disable_keys => true,
}

#
# use puppetlab's official apt repo to install the latest
# released version of puppet
#
apt::source { 'puppet':
  location => 'http://apt.puppetlabs.com/ubuntu',
  release  => 'natty',
  key      => '4BD6EC30',
}

#
# ensure that the latest version of puppet is installed
#
package { 'puppet':
  ensure  => latest,
  require => Apt::Source['puppet'],
}
