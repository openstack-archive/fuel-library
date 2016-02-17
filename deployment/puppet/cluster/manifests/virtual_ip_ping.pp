define cluster::virtual_ip_ping (
  $host_list = '127.0.0.1',
) {
  $vip_name = $title

  cs_resource { "ping_${vip_name}":
    ensure          => present,
    primitive_class => 'ocf',
    provided_by     => 'pacemaker',
    primitive_type  => 'ping',
    parameters      => {
      'host_list'  => $host_list,
      'multiplier' => '1000',
      'dampen'     => '30s',
      'timeout'    => '3s',
    },
    operations     => {
      'monitor' => {
        'interval' => '20',
        'timeout'  => '30',
      },
    },
    complex_type   => 'clone',
  }

  service { "ping_${vip_name}":
    ensure   => 'running',
    enable   => true,
    provider => 'pacemaker',
  }

  cs_rsc_location { "loc_ping_${vip_name}":
    primitive => $vip_name,
    cib       => "ping_${vip_name}",
    rules     => [
      {
        score            => '-INFINITY',
        boolean          => 'or',
        date_expressions => [],
        expressions      => [
          {
            attribute => 'pingd',
            operation => 'not_defined',
          },
          {
            attribute => "pingd",
            operation =>'lte',
            value     => '0',
          },
        ],
      },
    ],
  }

  Cs_resource["ping_${vip_name}"] ->
  Cs_rsc_location["loc_ping_${vip_name}"] ->
  Service["ping_${vip_name}"]
}

