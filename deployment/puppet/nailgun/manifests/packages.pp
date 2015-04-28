class nailgun::packages(
  $gem_source = "http://rubygems.org/",
  ){

  define nailgun_safe_package(){
    if ! defined(Package[$name]){
      package { $name : ensure => latest; }
    }
  }

  nailgun_safe_package { "rsyslog": }
  nailgun_safe_package { "rsync": }
  nailgun_safe_package { "fence-agents": }
  nailgun_safe_package { "python-fuelclient": }
  nailgun_safe_package { "screen": }
}
