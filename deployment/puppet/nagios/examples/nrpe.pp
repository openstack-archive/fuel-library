class {'nagios':
  proj_name       => 'test',
  services        => ['nova-compute','nova-network','libvirt'],
  whitelist       => ['127.0.0.1','10.0.97.5'],
  hostgroup       => 'compute',
}
