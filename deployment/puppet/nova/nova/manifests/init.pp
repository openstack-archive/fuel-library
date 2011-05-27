class nova(
  $verbose = false,
  $nodaemon = false
  $logdir = ''
  $sql_connection, 
  # just for network?
  $network_manager
) {

  class { 'puppet': }
  class {
    [
      'bzr',
      'git',
      'gcc',
      'extrapackages',
      # I may need to move python-mysqldb to elsewhere if it depends on mysql
      'python',
    ]:
  } 
  package { "python-greenlet": ensure => present }

  package { ["nova-common", "nova-doc"]:
    ensure => present,
    require => Package["python-greenlet"]
  }

  Nova_config<| |> { require +> Package["nova-common"] }
}
