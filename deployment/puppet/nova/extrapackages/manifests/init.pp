# unzip swig screen parted curl euca2ools - extra packages
class extrapackages {
  package { ['unzip', 'swig', 'screen', 'parted', 'curl', 'euca2ools']:
    ensure => present
  }
}
