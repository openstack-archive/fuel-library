class nailgun::packages(
  $gem_source = "http://rubygems.org/",
  ){

  define nailgun_safe_package(){
    if ! defined(Package[$name]){
      package { $name : ensure => latest; }
    }
  }

  nailgun_safe_package { "iptables": }
  nailgun_safe_package { "supervisor": }
  nailgun_safe_package { "nginx": }
  nailgun_safe_package { "crontabs": }
  nailgun_safe_package { "cronie-anacron": }
  nailgun_safe_package { "postgresql-libs": }
  nailgun_safe_package { "rsyslog": }
  nailgun_safe_package { "rsync": }
  nailgun_safe_package { "python-fuelclient": }
  nailgun_safe_package { "screen": }
  nailgun_safe_package { "fuel-migrate": }
  nailgun_safe_package { "acpid": }

  if $::osfamily == 'RedHat' {
    case $::operatingsystemmajrelease {
      '6': {
        nailgun_safe_package { "fence-agents": }
      }
      '7': {
        nailgun_safe_package { "fence-agents-all": }
      }
      default: {
        fail("Unsupported ${::osfamily} release: ${::operatingsystemmajrelease}")
      }
    }
  }
}
