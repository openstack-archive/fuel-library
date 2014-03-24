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

  $cobbler_url = "http://localhost/cobbler_api",
  $cobbler_user = "cobbler",
  $cobbler_password = "cobbler",

  $mco_pskey = "unset",
  $mco_vhost = "mcollective",
  $mco_host = $ipaddress,
  $mco_user = "mcollective",
  $mco_password = "marionette",
  $mco_connector = "rabbitmq",

  $astute_version,
  $nailgun_api_url = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/api",
  $rabbitmq_astute_user = "naily",
  $rabbitmq_astute_password = "naily",
  $puppet_master_hostname = "${hostname}.${domain}",
  $puppet_master_ip = $ipaddress,

  ) {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  anchor { "nailgun-begin": }
  anchor { "nailgun-end": }

  Anchor<| title == "nailgun-begin" |> ->
  Class["nailgun::packages"] ->
  Class["nailgun::iptables"] ->
  Class["nailgun::nginx-repo"] ->
  Exec["start_nginx_repo"] ->
  Class["nailgun::user"] ->
  Class["nailgun::logrotate"] ->
  Class["nailgun::rabbitmq"] ->
  Class["nailgun::venv"] ->
  Class["nailgun::astute"] ->
  Class["nailgun::nginx-nailgun"] ->
  Class["nailgun::cobbler"] ->
  Class["openstack::logging"] ->
  Class["nailgun::supervisor"] ->
  Anchor<| title == "nailgun-end" |>

  class { "nailgun::packages":
    gem_source => $gem_source,
  }

  firewall { '002 accept related established rules':
    proto   => 'all',
    state   => ['RELATED', 'ESTABLISHED'],
    action  => 'accept',
  } -> class { "nailgun::iptables": }

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
    rabbitmq_astute_user => $rabbitmq_astute_user,
    rabbitmq_astute_password => $rabbitmq_astute_password,

    admin_network         => ipcalc_network_by_address_netmask($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
    admin_network_cidr    => ipcalc_network_cidr_by_netmask($::fuel_settings['ADMIN_NETWORK']['netmask']),
    admin_network_size    => ipcalc_network_count_addresses($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
    admin_network_first   => $::fuel_settings['ADMIN_NETWORK']['static_pool_start'],
    admin_network_last    => $::fuel_settings['ADMIN_NETWORK']['static_pool_end'],
    admin_network_netmask => $::fuel_settings['ADMIN_NETWORK']['netmask'],
    admin_network_ip      => $::fuel_settings['ADMIN_NETWORK']['ipaddress']

  }

  class {"nailgun::astute":
    rabbitmq_astute_user => $astute_user,
    rabbitmq_astute_password => $astute_password,
    version => $astute_version,
    gem_source => $gem_source,
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

  class { "nailgun::cobbler":
    cobbler_user => "cobbler",
    cobbler_password => "cobbler",
    centos_repos => $centos_repos,
    gem_source => $gem_source,
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
  }

  class { "nailgun::gateone":
    pip_opts => "${pip_index} ${pip_find_links}",
  }

  class { "nailgun::puppetsync": }

  nailgun::sshkeygen { "/root/.ssh/id_rsa":
    homedir => "/root",
    username => "root",
    groupname => "root",
    keytype => "rsa",
  } ->

  exec { "cp /root/.ssh/id_rsa.pub /etc/cobbler/authorized_keys":
    command => "cp /root/.ssh/id_rsa.pub /etc/cobbler/authorized_keys",
    creates => "/etc/cobbler/authorized_keys",
    require => Class["nailgun::cobbler"],
  }

  file { "/etc/ssh/sshd_config":
    content => template("nailgun/sshd_config.erb"),
    owner => root,
    group => root,
    mode => 0600,
  }

  file { "/root/.ssh/config":
    content => template("nailgun/root_ssh_config.erb"),
    owner => root,
    group => root,
    mode => 0600,
  }

}
