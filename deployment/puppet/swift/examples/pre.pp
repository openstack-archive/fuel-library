# this file
# contains puppet resources
# that I used to set up my
# environment before installing swift

# set up all of the pre steps
# this shoud be run

# use the swift trunk ppa
class { 'swift::repo::trunk':}
class { 'apt':
  proxy_host   => '10.0.2.2',
  proxy_port   => '3128',
  disable_keys => true,
}

# use our apt repo
apt::source { 'puppet':
  location => 'http://apt.puppetlabs.com/ubuntu',
  release  => 'natty',
  key      => '4BD6EC30',
}

# install the latest version of Puppet
package { 'puppet':
  ensure  => latest,
  require => Apt::Source['puppet'],
}
