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
  nailgun_safe_package { "fence-agents": }
  nailgun_safe_package { "nailgun-redhat-license": }
  nailgun_safe_package { "python-fuelclient": }

}
