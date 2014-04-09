class swift::notify::ceilometer (
  $enable_ceilometer = false,
)
{
  if $enable_ceilometer {
    exec { "proxy_server_conf":
      command => '/bin/echo -e "\n[filter:ceilometer]\nuse=egg:ceilometer#swift" >> /etc/swift/proxy-server.conf',
      require => [Concat['/etc/swift/proxy-server.conf']],
    }
  }
}
