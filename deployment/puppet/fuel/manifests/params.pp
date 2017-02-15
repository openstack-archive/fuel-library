class fuel::params {

  case $::osfamily {
    'Debian': {
      $keystone_service_name = 'keystone'
    }
    'RedHat': {
      $keystone_service_name = 'openstack-keystone'
    }
    default: {
      fail("Unsupported osfamily ${::osfamily}")
    }
  }

  $db_engine                = 'postgresql'
  $db_host                  = '127.0.0.1'
  $db_port                  = '5432'

  $debug                    = false

  $nailgun_db_name          = 'nailgun'
  $nailgun_db_user          = 'nailgun'
  $nailgun_db_password      = 'nailgun'

  $keystone_db_name         = 'keystone'
  $keystone_db_user         = 'keystone'
  $keystone_db_password     = 'keystone'

  $feature_groups           = []
  $staticdir                = '/usr/share/nailgun/static'
  $templatedir              = '/usr/share/nailgun/static'
  $logdumpdir               = '/var/dump'

  # keystone
  $keystone_host              = '127.0.0.1'
  $keystone_port              = '5000'
  $keystone_admin_port        = '35357'
  $keystone_domain            = 'fuel'
  $ssl                        = false

  $vhost_limit_request_field_size = 'LimitRequestFieldSize 81900'

  $keystone_admin_user        = 'admin'
  $keystone_admin_password    = 'admin'
  $keystone_admin_tenant      = 'admin'
  $keystone_nailgun_user      = 'nailgun'
  $keystone_nailgun_password  = 'nailgun'
  $keystone_monitord_user     = 'monitord'
  $keystone_monitord_password = 'monitord'
  $keystone_monitord_tenant   = 'services'

  $keystone_admin_token       = 'admin'
  $keystone_token_expiration  = '86400'

  # network interface configuration timeout (in seconds)
  $bootstrap_ethdevice_timeout   = '120'
  $bootstrap_profile             = 'ubuntu_bootstrap'

  $rabbitmq_host                 = '127.0.0.1'
  $rabbitmq_astute_user          = 'naily'
  $rabbitmq_astute_password      = 'naily'

  $rabbitmq_gid                  = 495
  $rabbitmq_uid                  = 495
  $rabbitmq_management_port      = 15672
  $rabbitmq_management_bind_ip   = '127.0.0.1'

  $cobbler_host                  = $::ipaddress
  $cobbler_url                   = "http://${::ipaddress}/cobbler_api"
  $cobbler_user                  = 'cobbler'
  $cobbler_password              = 'cobbler'
  $centos_repos = [
    {
    'id'   => 'nailgun',
    'name' => 'Nailgun',
    'url'  => "\$tree"
    }
  ]

  $ks_system_timezone            = 'Etc/UTC'
  $dns_upstream                  = ['8.8.8.8']
  $dns_domain                    = 'domain.tld'
  $dns_search                    = 'domain.tld'
  $dhcp_ipaddress                = '127.0.0.1'
  $admin_interface               = 'eth0'
  $admin_network                 = '10.20.0.*'
  $extra_networks                = undef

  $nailgun_api_url               = "http://${::ipaddress}:8000/api"
  # default password is 'r00tme'
  $ks_encrypted_root_password    = '\$6\$tCD3X7ji\$1urw6qEMDkVxOkD33b4TpQAjRiCeDZx0jmgMhDYhfB9KuGfqO9OcMaKyUxnGGWslEDQ4HxTw7vcAMP85NxQe61'

  $ntp_upstream                  = ''

  $mco_host                      = $::ipaddress
  $mco_port                      = '61613'
  $mco_pskey                     = 'unset'
  $mco_vhost                     = 'mcollective'
  $mco_user                      = 'mcollective'
  $mco_password                  = 'marionette'
  $mco_connector                 = 'rabbitmq'
  $mco_packages_extra            = [
    'fuel-agent',
    'shotgun',
    'ironic-fa-bootstrap-configs',
    'fuel-bootstrap-cli',
  ]

  $keystone_ostf_user            = 'ostf'
  $keystone_ostf_password        = 'ostf'

  $puppet_master_hostname        = "${::hostname}.${::domain}"

  $repo_root                     = '/var/www/nailgun'
  $repo_port                     = '8080'

  $nailgun_log_level             = 'DEBUG'


  $nailgun_host                  = '127.0.0.1'
  $nailgun_port                  = '8000'
  $nailgun_internal_port         = '8001'
  $nailgun_serialization_port    = '8002'
  $nailgun_ssl_port              = '8443'

  $ostf_host                     = '127.0.0.1'
  $ostf_port                     = '8777'
  $ostf_db_user                  = 'ostf'
  $ostf_db_password              = 'ostf'
  $ostf_db_name                  = 'ostf'
}
