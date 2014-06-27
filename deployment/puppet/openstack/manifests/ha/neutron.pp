# HA configuration for OpenStack Neutron
class openstack::ha::neutron {

  openstack::ha::haproxy_service { 'neutron':
    order           => '085',
    listen_port     => 9696,
    public          => true,
    define_backups  => true,
  }

  Openstack::Ha::Haproxy_service<| title == 'mysqld' |> -> Exec <| title == 'neutron-db-sync' |>
  Openstack::Ha::Haproxy_service<| title == 'mysqld' |> -> Service<| title == 'neutron-server'|>

  Openstack::Ha::Haproxy_service<| title == 'keystone-1' or title == 'keystone-2'|> -> Service<| title == 'neutron-server'|>
  #Openstack::Ha::Haproxy_service['neutron'] -> Service<| title == 'neutron-server'|>
  Exec['haproxy reload for neutron'] -> Service<| title == 'neutron-server'|>

}
