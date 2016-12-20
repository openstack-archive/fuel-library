class osnailyfacter::cluster_haproxy::restart_haproxy {

  notice('MODULAR: cluster_haproxy/restart_haproxy.pp')

  notify { 'Haproxy service will be restarted': } ~>

  service { 'haproxy' :
      ensure     => 'running',
      name       => 'p_haproxy',
      provider   => 'pacemaker',
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
  }
}
