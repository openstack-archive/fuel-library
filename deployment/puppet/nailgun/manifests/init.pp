class nailgun(
  $package,
  $version,
  $production,
  $venv,
  $nailgun_group = "nailgun",
  $nailgun_user = "nailgun",

  $repo_root = "/var/www/nailgun",
  $pip_index = "",
  $pip_find_links = "",
  $gem_source = "http://localhost/gems/",

  $database_name = "nailgun",
  $database_engine = "postgresql",
  $database_host = "localhost",
  $database_port = "5432",
  $database_user = "nailgun",
  $database_passwd = "nailgun",

  $staticdir,
  $templatedir,
  $logdumpdir = "/var/www/nailgun/dump",

  $cobbler_user = "cobbler",
  $cobbler_password = "cobbler",
  $cobbler_host       = $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  $cobbler_url        = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}/cobbler_api",
  $dns_upstream       = $::fuel_settings['DNS_UPSTREAM'],
  $dns_domain         = $::fuel_settings['DNS_DOMAIN'],
  $dns_search         = $::fuel_settings['DNS_SEARCH'],
  $dhcp_start_address = $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_start'],
  $dhcp_end_address   = $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_end'],
  $dhcp_netmask       = $::fuel_settings['ADMIN_NETWORK']['netmask'],
  $dhcp_mac           = $::fuel_settings['ADMIN_NETWORK']['mac'],
  $dhcp_interface     = $::fuel_settings['ADMIN_NETWORK']['interface'],

  $mco_pskey = "unset",
  $mco_vhost = "mcollective",
  $mco_host = $ipaddress,
  $mco_user = "mcollective",
  $mco_password = "marionette",
  $mco_connector = "rabbitmq",

  $astute_version,
  $nailgun_api_url = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/api",
  $rabbitmq_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  $rabbitmq_astute_user = "naily",
  $rabbitmq_astute_password = "naily",
  $puppet_master_hostname = "${hostname}.${domain}",
  $puppet_master_ip = $ipaddress,

  $keystone_admin_token = $keystone_admin_token,
  $keystone_host        = $keystone_host,

  ) {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  anchor { "nailgun-begin": }
  anchor { "nailgun-end": }

  Anchor<| title == "nailgun-begin" |> ->
  Class["nailgun::packages"] ->
  Class["nailgun::nginx-repo"] ->
  Exec["start_nginx_repo"] ->
  Class["nailgun::user"] ->
  Class["nailgun::logrotate"] ->
  Class["nailgun::rabbitmq"] ->
  Class["nailgun::mcollective"] ->
  Class["nailgun::venv"] ->
  Class["nailgun::astute"] ->
  Class["nailgun::nginx-nailgun"] ->
  Class["nailgun::host"] ->
  Class["nailgun::cobbler"] ->
  Class["openstack::logging"] ->
  Class["nailgun::supervisor"] ->
  Anchor<| title == "nailgun-end" |>

  class { 'nailgun::host':
    production => $production,
    cobbler_host => $cobbler_host,
    nailgun_group => $nailgun_group,
    nailgun_user => $nailgun_user,
  }

  class { "nailgun::packages":
    gem_source => $gem_source,
  }

  file { ["/etc/nginx/conf.d/default.conf",
          "/etc/nginx/conf.d/virtual.conf",
          "/etc/nginx/conf.d/ssl.conf"]:
    ensure => "absent",
    notify => Service["nginx"],
    before => [
               Class["nailgun::nginx-repo"],
               Class["nailgun::nginx-nailgun"],
               ],
  }
  class {openstack::logging:
    role           => 'server',
    log_remote     => false,
    log_local      => true,
    log_auth_local => true,
    rotation       => 'weekly',
    keep           => '4',
    # should be > 30M
    limitsize      => '100M',
    port           => '514',
    # listen both TCP and UDP
    proto          => 'both',
    # use date-rfc3339 timestamps
    show_timezone  => true,
    virtual        => str2bool($::is_virtual),
    production     => $production,
  }

  class { "nailgun::user":
    nailgun_group => $nailgun_group,
    nailgun_user => $nailgun_user,
  }

  class { "nailgun::venv":
    venv => $venv,
    venv_opts => "--system-site-packages",
    package => $package,
    version => $version,
    pip_opts => "${pip_index} ${pip_find_links}",
    production => $production,
    nailgun_user => $nailgun_user,
    nailgun_group => $nailgun_group,

    database_name   => $database_name,
    database_engine => $database_engine,
    database_host   => $database_host,
    database_port   => $database_port,
    database_user   => $database_user,
    database_passwd => $database_passwd,

    staticdir => $staticdir,
    templatedir => $templatedir,
    rabbitmq_host => $rabbitmq_host,
    rabbitmq_astute_user => $rabbitmq_astute_user,
    rabbitmq_astute_password => $rabbitmq_astute_password,

    admin_network         => ipcalc_network_by_address_netmask($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
    admin_network_cidr    => ipcalc_network_cidr_by_netmask($::fuel_settings['ADMIN_NETWORK']['netmask']),
    admin_network_size    => ipcalc_network_count_addresses($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
    admin_network_first   => $::fuel_settings['ADMIN_NETWORK']['static_pool_start'],
    admin_network_last    => $::fuel_settings['ADMIN_NETWORK']['static_pool_end'],
    admin_network_netmask => $::fuel_settings['ADMIN_NETWORK']['netmask'],
    admin_network_mac     => $::fuel_settings['ADMIN_NETWORK']['mac'],
    admin_network_ip      => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],

    cobbler_host     => $cobbler_host,
    cobbler_url      => $cobbler_url,
    cobbler_user     => $cobbler_user,
    cobbler_password => $cobbler_password,

    mco_pskey     => $mco_pskey,
    mco_vhost     => $mco_vhost,
    mco_host      => $mco_host,
    mco_user      => $mco_user,
    mco_password  => $mco_password,
    mco_connector => $mco_connector,

    puppet_master_hostname => $puppet_master_hostname,

    keystone_admin_token => $::fuel_settings['keystone']['admin_token'],
    keystone_host        => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  }

  class {"nailgun::astute":
    production               => $production,
    rabbitmq_host            => $rabbitmq_host,
    rabbitmq_astute_user     => $rabbitmq_astute_user,
    rabbitmq_astute_password => $rabbitmq_astute_password,
    version                  => $astute_version,
    gem_source               => $gem_source,
  }

  if $production == 'prod' {
    $nailgun_env = $venv
    $ostf_env = $venv
  } else {
    $nailgun_env = '/opt/nailgun'
    $ostf_env = '/opt/fuel_plugins/ostf'
  }

  class { "nailgun::supervisor":
    nailgun_env => $nailgun_env,
    ostf_env => $ostf_env,
  }

  class { "nailgun::nginx-repo":
    repo_root => $repo_root,
    notify => Service["nginx"],
  }

  exec { "start_nginx_repo":
    command => "/etc/init.d/nginx start",
    unless => "/etc/init.d/nginx status | grep -q running",
  }

  class { "nailgun::nginx-nailgun":
    staticdir => $staticdir,
    logdumpdir => $logdumpdir,
    notify => Service["nginx"],
  }

  class { "nailgun::uwsgi":
    venv => $venv,
  }

  class { "nailgun::cobbler":
    production         => $production,
    centos_repos       => $centos_repos,
    gem_source         => $gem_source,

    cobbler_user       => $cobbler_user,
    cobbler_password   => $cobbler_password,
    server             => $cobbler_host,
    name_server        => $cobbler_host,
    next_server        => $cobbler_host,
    dns_upstream       => $dns_upstream,
    domain_name        => $dns_domain,
    dns_search         => $dns_search,

    mco_user           => $mco_user,
    mco_pass           => $mco_password,

    dhcp_start_address => $dhcp_start_address,
    dhcp_end_address   => $dhcp_end_address,
    dhcp_netmask       => $dhcp_netmask,
    dhcp_gateway       => $cobbler_host,
    dhcp_interface     => $dhcp_interface,
    nailgun_api_url    => $nailgun_api_url,
  }

  class { "nailgun::mcollective":
    mco_pskey => $mco_pskey,
    mco_user => $mco_user,
    mco_password => $mco_password,
    mco_vhost => $mco_vhost,
  }

  if $production !~ /docker/ {
    class { "nailgun::database":
      user      => $database_user,
      password  => $database_passwd,
      dbname    => $database_name,
    }

    Class["nailgun::database"] ->
    Class["nailgun::venv"]
  }

  class { "nailgun::rabbitmq":
    production      => $production,
    astute_user     => $rabbitmq_astute_user,
    astute_password => $rabbitmq_astute_password,
    mco_user        => $mco_user,
    mco_password    => $mco_password,
    mco_vhost       => $mco_vhost,
  }

  class { "nailgun::nginx-service": }

  class { "nailgun::logrotate": }

  class { "nailgun::ostf":
    production => $production,
    pip_opts => "${pip_index} ${pip_find_links}",
    keystone_admin_token => $keystone_admin_token,
    keystone_host        => $keystone_host,
  }

  class { "nailgun::puppetsync": }
}
