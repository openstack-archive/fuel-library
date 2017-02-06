class osnailyfacter::cluster_haproxy::restart_haproxy {

  notice('MODULAR: cluster_haproxy/restart_haproxy.pp')

  include openstack::ha::haproxy_restart
  notify { 'Haproxy service will be restarted':
    notify => Exec['haproxy-restart'],
  }
}
