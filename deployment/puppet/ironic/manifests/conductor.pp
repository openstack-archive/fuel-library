class ironic::conductor {

  file { '/etc/ironic/rootwrap.conf' :
    source => 'puppet:///modules/ironic/rootwrap.conf',
  }

  file { '/etc/ironic/rootwrap.d' :
    recurse => true,
    source => "puppet:///modules/ironic/rootwrap.d"
  }

  ironic_config {
      'DEFAULT/rootwrap_config': value => '/etc/ironic/rootwrap.conf';
  }

}
