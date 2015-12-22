# == Class: sysfs::install
#
# This class installs the sysfsutils packages and prepares the config directory
#

class sysfs::install inherits sysfs::params {

  File {
    owner => 'root',
    group => 'root',
    mode  => '0755',
  }

  #TODO: should be moved to the fuel-library package or sysfsutils package
  if $::osfamily == 'RedHat' {
    file { 'sysfsutils.init' :
      ensure => 'present',
      name   => "/etc/init.d/${service}",
      source => 'puppet:///modules/sysfs/centos-sysfsutils.init.sh',
    }
  }

  package { 'sysfsutils' :
    ensure => 'installed',
    name   => $package,
  }

  file { 'sysfs.d' :
    ensure => 'directory',
    name   => $config_dir,
  }
}
