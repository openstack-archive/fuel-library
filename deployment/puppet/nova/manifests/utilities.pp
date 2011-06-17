# unzip swig screen parted curl euca2ools - extra packages
class nova::utilities {
  package { ['unzip', 'screen', 'parted', 'curl', 'euca2ools']:
    ensure => present
  }
}
