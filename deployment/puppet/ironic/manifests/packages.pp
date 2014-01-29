class ironic::packages {
  define ironic_safe_package(){
    if ! defined(Package[$name]){
      @package { $name : }
    }
  }

  ironic_safe_package {"gcc": }
  ironic_safe_package {"gcc-c++": }
  ironic_safe_package {"make": }
  ironic_safe_package {"python-virtualenv": }
  ironic_safe_package {"postgresql-libs": }
  ironic_safe_package {"postgresql-devel": }
  ironic_safe_package {"numpy": }
  ironic_safe_package {"python-devel": }
  ironic_safe_package {"libxml2-devel": }
  ironic_safe_package {"libxslt-devel": }
}
