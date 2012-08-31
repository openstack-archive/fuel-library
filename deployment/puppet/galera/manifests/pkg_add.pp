define galera::pkg_add(
  $pkg_name, 
  $pkg_prefix = '/tmp'
) {

  include galera::params

  package { $title :
    ensure   => present,
    provider => $::galera::params::pkg_provider,
    source   => "${pkg_prefix}/${pkg_name}",
  } 

}



