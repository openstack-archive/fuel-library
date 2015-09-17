define cluster::virtual_ip_ping (
  $host_list = '127.0.0.1',
) {
  $vip_name = $title

  pcmk_resource { "ping_${vip_name}":
    ensure             => 'present',
    primitive_class    => 'ocf',
    primitive_provider => 'pacemaker',
    primitive_type     => 'ping',
    parameters         => {
      'host_list'  => $host_list,
      'multiplier' => '1000',
      'dampen'     => '30s',
      'timeout'    => '3s',
    },
    operations         => {
      'monitor' => {
        'interval' => '20',
        'timeout'  => '30',
      },
    },
    complex_type       => 'clone',
  }

  service { "${vip_name}":
    ensure   => 'running',
    enable   => true,
    provider => 'pacemaker'
  }

  service { "ping_${vip_name}":
    ensure   => 'running',
    enable   => true,
    provider => 'pacemaker',
  }

  pcmk_location { "loc_ping_${vip_name}":
    primitive => $vip_name,
    rules     => [
      {
        'score'   => '-inf',
        'boolean' => '',
        'expressions' => [
          {
            'attribute' => "not_defined",
            'operation' => 'pingd',
            'value' => 'or',
          },
          {
            'attribute' => "pingd",
            'operation'=>'lte',
            'value' => '0',
          },
        ],
      },
    ],
  }

  Pcmk_resource["ping_${vip_name}"] ->
  Pcmk_location["loc_ping_${vip_name}"] ->
  Service["ping_${vip_name}"] ->
  Service <| title == "${vip_name}" |>
}
