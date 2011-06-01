# all of the openstack specific stuff is being moved to herej
class nova::rackspace::dev() {

  class { 'puppet': }
  class {
    [
      'bzr',
      'git',
      'gcc',
      # I may need to move python-mysqldb to elsewhere if it depends on mysql
      # python-nova pulls in all of the deps mentioned here
      'python',
    ]:
  } 
  package { 'swig':
    ensure => installed,
  }

}
