class mongodb::sources::yum inherits mongodb::params {
  yumrepo { '10gen':
    descr    => 'MongoDB/10gen Repository',
    baseurl  => $mongodb::params::baseurl,
    gpgcheck => '0',
    enabled  => '1',
  }
}
