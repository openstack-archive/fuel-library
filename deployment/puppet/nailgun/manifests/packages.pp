class nailgun::packages(
  $production = 'prod',
  $gem_source = "http://rubygems.org/",
  ){

  define nailgun_safe_package(){
    if ! defined(Package[$name]){
      @package { $name : }
    }
  }

  nailgun_safe_package { "supervisor": }
  nailgun_safe_package { "nginx": }
  if ( $production == 'dev' ) {
    nailgun_safe_package { "python-virtualenv": }
    nailgun_safe_package { "python-devel": }
    nailgun_safe_package { "postgresql-devel": }
    nailgun_safe_package { "ruby-devel": }
    nailgun_safe_package { "gcc": }
    nailgun_safe_package { "gcc-c++": }
    nailgun_safe_package { "make": }
  }

  nailgun_safe_package { "postgresql-libs": }
  nailgun_safe_package { "rsyslog": }

  #  nailgun_safe_package { "cman": }
  nailgun_safe_package { "fence-agents": }
  nailgun_safe_package { "nailgun-redhat-license": }
  nailgun_safe_package { "python-fuelclient": }

}
