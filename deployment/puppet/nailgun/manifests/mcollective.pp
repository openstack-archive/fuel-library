class nailgun::mcollective
{
  define mcollective_safe_package(){
    if ! defined(Package[$name]){
      package { $name : ensure => latest; }
    }
  }

  mcollective_safe_package { "fuel-agent": }
  mcollective_safe_package { "fuel-provisioning-scripts": }
  mcollective_safe_package { "shotgun": }
}
