class nailgun(
  $package,
  $version,
  $nailgun_group = "nailgun",
  $nailgun_user = "nailgun",
  $venv = "/opt/nailgun",

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

  $staticdir = "/opt/nailgun/share/nailgun/static",
  $templatedir = "/opt/nailgun/share/nailgun/static",
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

  $naily_version,
  $nailgun_api_url = "http://{$::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/api",
  $rabbitmq_naily_user = "naily",
  $rabbitmq_naily_password = "naily",
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
  Class["nailgun::venv"] ->
  Class["nailgun::naily"] ->
  Class["nailgun::nginx-nailgun"] ->
  Class["nailgun::cobbler"] ->
  Class["nailgun::pm"] ->
  Class["openstack::logging"] ->
  Class["nailgun::supervisor"] ->
  Anchor<| title == "nailgun-end" |>

  class { "nailgun::packages":
    gem_source => $gem_source,
  }

  class { "nailgun::iptables": }

  file { ["/etc/nginx/conf.d/default.conf",
          "/etc/nginx/conf.d/virtual.conf",
          "/etc/nginx/conf.d/ssl.conf"]:
    ensure => "absent",
    notify => Service["nginx"],
    before => [
               Class["nailgun::nginx-repo"],
               Class["nailgun::nginx-nailgun"],
               Class["nailgun::pm"],
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
    proto          => 'udp',
    # use date-rfc3339 timestamps
    show_timezone  => true,
    virtual        => true,
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
    nailgun_user => $nailgun_user,
    nailgun_group => $nailgun_group,

    database_name => "nailgun",
    database_engine => "postgresql",
    database_host => "localhost",
    database_port => "5432",
    database_user => "nailgun",
    database_passwd => "nailgun",

    staticdir => $staticdir,
    templatedir => $templatedir,
    rabbitmq_naily_user => $rabbitmq_naily_user,
    rabbitmq_naily_password => $rabbitmq_naily_password,

    admin_network         => ipcalc_network_by_address_netmask($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
    admin_network_cidr    => ipcalc_network_cidr_by_netmask($::fuel_settings['ADMIN_NETWORK']['netmask']),
    admin_network_size    => ipcalc_network_count_addresses($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
    admin_network_first   => $::fuel_settings['ADMIN_NETWORK']['static_pool_start'],
    admin_network_last    => $::fuel_settings['ADMIN_NETWORK']['static_pool_end'],
    admin_network_netmask => $::fuel_settings['ADMIN_NETWORK']['netmask'],
    admin_network_ip      => $::fuel_settings['ADMIN_NETWORK']['ipaddress']

  }

  class {"nailgun::naily":
    rabbitmq_naily_user => $naily_user,
    rabbitmq_naily_password => $naily_password,
    version => $naily_version,
    gem_source => $gem_source,
  }

  class { "nailgun::supervisor":
    venv => $venv,
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

  class { "nailgun::pm":
    puppet_master_hostname => $puppet_master_hostname,
  }

  class { "nailgun::mcollective":
    mco_pskey => $mco_pskey,
    mco_user => $mco_user,
    mco_password => $mco_password,
    mco_vhost => $mco_vhost,
  }

  class { "nailgun::database":
    user      => $database_user,
    password  => $database_passwd,
    dbname    => $database_name,
  }

  rabbitmq_user { $rabbitmq_naily_user:
    admin     => true,
    password  => $rabbitmq_naily_password,
    provider  => 'rabbitmqctl',
    require   => Class['rabbitmq::server'],
  }

  rabbitmq_user_permissions { "${rabbitmq_naily_user}@/":
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => Class['rabbitmq::server'],
  }

  class { "nailgun::nginx-service": }

  class { "nailgun::logrotate": }

  class { "nailgun::ostf":
    pip_opts => "${pip_index} ${pip_find_links}",
  }

  class { "nailgun::gateone":
    pip_opts => "${pip_index} ${pip_find_links}",
  }

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
