class neutron::agents::metadata (
  $neutron_config     = {},
  $debug            = false,
  $verbose          = false,
  $service_provider = 'generic'
) {

  $cib_name = "neutron-metadata-agent"
  $res_name = "p_$cib_name"

  include 'neutron::params'

  Anchor<| title=='neutron-server-done' |> ->
  anchor {'neutron-metadata-agent': }
  Anchor <| title == 'neutron-ovs-agent-done' |> -> Anchor['neutron-metadata-agent']

  # add instructions to nova.conf
  nova_config {
    'DEFAULT/service_neutron_metadata_proxy':       value => true;
    'DEFAULT/neutron_metadata_proxy_shared_secret': value => $neutron_config['metadata']['metadata_proxy_shared_secret'];
  } -> Nova::Generic_service<| title=='api' |>

  neutron_metadata_agent_config {
    'DEFAULT/debug':              value => $debug;
    'DEFAULT/verbose':            value => $verbose;
    'DEFAULT/log_dir':           ensure => absent;
    'DEFAULT/log_file':          ensure => absent;
    'DEFAULT/log_config':        ensure => absent;
    'DEFAULT/use_syslog':        ensure => absent;
    'DEFAULT/use_stderr':        ensure => absent;
    'DEFAULT/auth_region':        value => $neutron_config['keystone']['auth_region'];
    'DEFAULT/auth_url':           value => $neutron_config['keystone']['auth_url'];
    'DEFAULT/admin_user':         value => $neutron_config['keystone']['admin_user'];
    'DEFAULT/admin_password':     value => $neutron_config['keystone']['admin_password'];
    'DEFAULT/admin_tenant_name':  value => $neutron_config['keystone']['admin_tenant_name'];
    'DEFAULT/nova_metadata_ip':   value => $neutron_config['metadata']['nova_metadata_ip'];
    'DEFAULT/nova_metadata_port': value => $neutron_config['metadata']['nova_metadata_port'];
    'DEFAULT/use_namespaces':     value => $neutron_config['L3']['use_namespaces'];
    'DEFAULT/metadata_proxy_shared_secret': value => $neutron_config['metadata']['metadata_proxy_shared_secret'];
  }

  if $::neutron::params::metadata_agent_package {
    package { 'neutron-metadata-agent':
      name   => $::neutron::params::metadata_agent_package,
      ensure => present,

    }
    # do not move it to outside this IF
    Anchor['neutron-metadata-agent'] ->
      Package['neutron-metadata-agent'] ->
        Neutron_metadata_agent_config<||>
  }

  if $service_provider == 'generic' {
    # non-HA architecture
    service { 'neutron-metadata-agent':
      name    => $::neutron::params::metadata_agent_service,
      enable  => true,
      ensure  => running,
    }

    Anchor['neutron-metadata-agent'] ->
      Neutron_metadata_agent_config<||> ->
        Service['neutron-metadata-agent'] ->
          Anchor['neutron-metadata-agent-done']
  } else {
    # OCF script for pacemaker
    # and his dependences
    file {'neutron-metadata-agent-ocf':
      path   =>'/usr/lib/ocf/resource.d/mirantis/neutron-agent-metadata',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => "puppet:///modules/neutron/ocf/neutron-agent-metadata",
    }
    Package['pacemaker'] -> File['neutron-metadata-agent-ocf']
    File<| title == 'ocf-mirantis-path' |> -> File['neutron-metadata-agent-ocf']
    Anchor['neutron-metadata-agent'] -> File['neutron-metadata-agent-ocf']
    Neutron_metadata_agent_config<||> -> File['neutron-metadata-agent-ocf']
    File['neutron-metadata-agent-ocf'] -> Cs_resource["$res_name"]

    service { 'neutron-metadata-agent__disabled':
      name    => $::neutron::params::metadata_agent_service,
      enable  => false,
      ensure  => stopped,
    }
    Cs_commit <| title == 'ovs' |> -> Cs_shadow <| title == "$res_name" |>

    Anchor['neutron-metadata-agent'] -> Cs_shadow["$cib_name"]
    cs_shadow { $cib_name: cib => $cib_name }
    cs_commit { $cib_name: cib => $cib_name }

    File<| title=='neutron-logging.conf' |> ->
    cs_resource { "$res_name":
      ensure          => present,
      cib             => $cib_name,
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => 'neutron-agent-metadata',
      parameters => {
        #'nic'     => $vip[nic],
        #'ip'      => $vip[ip],
        #'iflabel' => $vip[iflabel] ? { undef => 'ka', default => $vip[iflabel] },
      },
      multistate_hash => {
        'type' => 'clone',
      },
      ms_metadata     => {
        'interleave' => 'true',
      },
      operations => {
        'monitor' => {
          'interval' => '60',
          'timeout'  => '10'
        },
        'start' => {
          'timeout' => '30'
        },
        'stop' => {
          'timeout' => '30'
        },
      },
    }

    Cs_resource["$res_name"] ->
      Cs_commit["$cib_name"]

    service {"$res_name":
      name       => $res_name,
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      provider   => "pacemaker"
    }

    Anchor['neutron-metadata-agent'] ->
      Service['neutron-metadata-agent__disabled'] ->
        Cs_resource["$res_name"] ->
         Cs_commit["$cib_name"] ->
          Service["$res_name"] ->
            Anchor['neutron-metadata-agent-done']
  }
  anchor {'neutron-metadata-agent-done': }
  Package<| title == 'neutron-metadata-agent'|> ~> Service<| title == 'neutron-metadata-agent'|>
  if !defined(Service['neutron-metadata-agent']) {
    notify{ "Module ${module_name} cannot notify service neutron-metadata-agent on package update": }
  }
}

