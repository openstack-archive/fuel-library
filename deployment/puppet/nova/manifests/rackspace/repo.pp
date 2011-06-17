class nova::rackspace::repo {
  # this should not be hard-coded
  # eventually this will be on a real debian repo
  apt::source { 'openstack':
    location    => 'http://jenkins.ohthree.com',
    release     => 'unstable',
    repos       => 'main',
    include_src => false,
  }
}
