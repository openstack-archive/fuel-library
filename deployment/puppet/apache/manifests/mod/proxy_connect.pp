class apache::mod::proxy_connect {
  Class['::apache::mod::proxy'] -> Class['::apache::mod::proxy_connect']
  ::apache::mod { 'proxy_connect': }
}
