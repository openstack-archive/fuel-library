define twemproxy::member (
  $order,
  $client_address = undef,
  $client_port    = undef,
  $client_weight  = undef,
  $clients_array  = undef,
) {

  if $client_address and $clients_array {
    fail('clients_array is mutual exclusive with client_address parameter')
  }

  concat::fragment { "${name}_member_block":
    order   => "01_${order}",
    target  => '/etc/nutcracker.yml',
    content => template('twemproxy/twemproxy_member_block.erb'),
  }
}
