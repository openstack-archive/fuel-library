class nailgun::params {

  $production                    = 'prod'

  $bootstrap_flavor              = 'centos'
  # network interface configuration timeout (in seconds)
  $bootstrap_ethdevice_timeout   = '120'

  $rabbitmq_host                 = 'localhost'
  $rabbitmq_astute_user          = 'naily'
  $rabbitmq_astute_password      = 'naily'

  $pip_repo                      = "/var/www/nailgun/eggs"
  $gem_source                    = "http://rubygems.org/"

  $cobbler_host                  = $::ipaddress
  $cobbler_user                  = 'cobbler'
  $cobbler_password              = 'cobbler'
  $centos_repos = [
    {
    "id" => "nailgun",
    "name" => "Nailgun",
    "url"  => "\$tree"
    }
  ]

  $ks_system_timezone            = 'Etc/UTC'
  $dns_upstream                  = '8.8.8.8'
  $dns_domain                    = 'domain.tld'
  $dns_search                    = 'domain.tld'
  $dhcp_interface                = "eth0"

  $nailgun_api_url               = "http://${::ipaddress}:8000/api"
  # default password is 'r00tme'
  $ks_encrypted_root_password    = '\$6\$tCD3X7ji\$1urw6qEMDkVxOkD33b4TpQAjRiCeDZx0jmgMhDYhfB9KuGfqO9OcMaKyUxnGGWslEDQ4HxTw7vcAMP85NxQe61'

  $ntp_upstream                  = ''

  $env_path                      = '/usr'
  $staticdir                     = '/usr/share/nailgun/static'

  $mco_host                      = $::ipaddress
  $mco_port                      = '61613'
  $mco_pskey                     = 'unset'
  $mco_vhost                     = 'mcollective'
  $mco_user                      = 'mcollective'
  $mco_pass                      = 'marionette'
  $mco_connector                 = 'rabbitmq'

  $keystone_db_user              = "keystone"
  $keystone_db_password          = "keystone"
  $keystone_db_address           = "127.0.0.1"
  $keystone_db_port              = "5432"
  $keystone_db_name              = "keystone"

  $keystone_auth_version         = "v2.0"
  $keystone_nailgun_user         = "nailgun"
  $keystone_nailgun_password     = "nailgun"
  $keystone_ostf_user            = "ostf"
  $keystone_ostf_password        = "ostf"
  $keystone_address              = '127.0.0.1'

  # this replaces removed postgresql version fact
  $postgres_default_version = '9.3'

  $puppet_master_hostname = "${hostname}.${domain}"

  $repo_root = "/var/www/nailgun"

  $nailgun_package = "Nailgun"
  $nailgun_version = "0.1.0"

  $nailgun_user = "nailgun"
  $nailgun_group = "nailgun"
  $nailgun_log_level = "INFO"
  $nailgun_feature_groups = []

  $nailgun_db_engine = "postgresql"
  $nailgun_db_port = "5432"
  $nailgun_db_host = "127.0.0.1"
  $nailgun_db_name = "nailgun"
  $nailgun_db_user = "nailgun"
  $nailgun_db_password = "nailgun"

  $nailgun_host = '127.0.0.1'
  $nailgun_port = '8000'

  $ostf_db_user              = "ostf"
  $ostf_db_password          = "ostf"
  $ostf_db_address           = "127.0.0.1"
  $ostf_db_port              = "5432"
  $ostf_db_name              = "ostf"

}
