define galera::pkg_add(
  $pkg_version, 
  $pkg_prefix = '/tmp'
) {

  include galera::params

  package { $title :
    ensure   => present,
    provider => $::galera::params::pkg_provider,
    source   => "${pkg_prefix}/${title}-${pkg_version}.rpm",
  } 

}
