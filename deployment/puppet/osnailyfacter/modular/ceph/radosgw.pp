### TODO(omolchanov) - bug #1580656
if $::osfamily == 'Debian' {
  $service_provider = 'upstart'
}

class { '::osnailyfacter::ceph::radosgw' :}
