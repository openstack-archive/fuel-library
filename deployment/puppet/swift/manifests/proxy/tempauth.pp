class swift::proxy::tempauth() {

  concat::fragment { 'swift-proxy-swauth':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/tempauth.conf.erb'),
    order   => '01',
  }

}
