define cluster::virtual_ip_ping (
  $host_list = '127.0.0.1',
) {
  $vip_name      = $name
  $service_name  = "ping_${vip_name}"
  $location_name = "loc_ping_${vip_name}"

  $primitive_class    = 'ocf'
  $primitive_provider = 'pacemaker'
  $primitive_type     = 'ping'
  $parameters         = {
    'host_list'  => $host_list,
    'multiplier' => '1000',
    'dampen'     => '30s',
    'timeout'    => '3s',
  }
  $operations         = {
    'monitor' => {
      'interval' => '20',
      'timeout'  => '30',
    },
  }
  $complex_type       = 'clone'

  service { $service_name :
    ensure   => 'running',
    enable   => true,
  }

  pacemaker::service { $service_name :
    prefix             => false,
    primitive_class    => $primitive_class,
    primitive_provider => $primitive_provider,
    primitive_type     => $primitive_type,
    parameters         => $parameters,
    operations         => $operations,
    complex_type       => $complex_type,
  }

  pcmk_location { $location_name :
    primitive => $vip_name,
    rules     => [
      {
        'score'   => '50',
        'expressions' => [
          {
            'attribute' => "pingd",
            'operation' => 'defined',
          },
          {
            'attribute' => "pingd",
            'operation' => 'gte',
            'value'     => '1',
          },
        ],
      },
    ],
  }

  Pcmk_resource[$service_name] ->
  Pcmk_location[$location_name] ->
  Service[$service_name]
}
