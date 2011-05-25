class nova::repo {
  apt::source { 'openstack':
    location => 'http://jenkins.ohthree.com',
    release => 'unstable',
    repos => 'main',
    include_src => false,
  }
}
