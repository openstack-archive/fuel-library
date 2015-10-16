define nailgun::nailgun_safe_package() {
  if ! defined(Package[$name]){
    package { $name : ensure => latest; }
  }
}
