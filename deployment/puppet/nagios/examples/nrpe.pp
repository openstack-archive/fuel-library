## proj_name => isolated configuration for project
## services  =>  array of services which you want use
## whitelist =>  array of IP addreses which NRPE trusts
## hostgroup =>  group wich will use in nagios master
# do not forget create it in nagios master

class {'nagios':
  proj_name       => 'test',
  services        => ['nova-compute','nova-network','libvirt'],
  whitelist       => ['127.0.0.1','10.0.97.5'],
  hostgroup       => 'compute',
}
