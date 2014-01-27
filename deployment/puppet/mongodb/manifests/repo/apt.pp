class mongodb::repo::apt inherits mongodb::repo {
  # we try to follow/reproduce the instruction
  # from http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/

  include ::apt

  if($ensure == 'present' or $ensure == true) {
    apt::source { 'downloads-distro.mongodb.org':
      location    => $location,
      release     => 'dist',
      repos       => '10gen',
      key         => '7F0CEB10',
      key_server  => 'keyserver.ubuntu.com',
      include_src => false,
    }

    Apt::Source['downloads-distro.mongodb.org']->Package<|tag == 'mongodb'|>
  }
  else {
    apt::source { 'downloads-distro.mongodb.org':
      ensure => absent,
    }
  }

}
