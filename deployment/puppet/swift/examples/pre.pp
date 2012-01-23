# this file
# contains puppet resources
# that I used to set up my
# environment before installing swift

# set up all of the pre steps
# this shoud be run

class { 'apt':}
# use the swift trunk ppa
class { 'swift::repo::trunk':}

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
