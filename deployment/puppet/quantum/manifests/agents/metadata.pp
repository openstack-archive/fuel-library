class quantum::agents::metadata (
  $quantum_config     = {},
  $debug            = false,
  $verbose          = false,
  $service_provider = 'generic'
) {

  $cib_name = "quantum-metadata-agent"
  $res_name = "p_$cib_name"

  include 'quantum::params'

  anchor {'quantum-metadata-agent': }

  Service<| title=='quantum-server' |> -> Anchor['quantum-metadata-agent']

  # add instructions to nova.conf
  nova_config {
    'DEFAULT/service_quantum_metadata_proxy':       value => true;
    'DEFAULT/quantum_metadata_proxy_shared_secret': value => $quantum_config['metadata']['metadata_proxy_shared_secret'];
  } -> Nova::Generic_service<| title=='api' |>

  quantum_metadata_agent_config {
    'DEFAULT/debug':              value => $debug;
    'DEFAULT/auth_region':        value => $quantum_config['keystone']['auth_region'];
    'DEFAULT/auth_url':           value => $quantum_config['keystone']['auth_url'];
    'DEFAULT/admin_user':         value => $quantum_config['keystone']['admin_user'];
    'DEFAULT/admin_password':     value => $quantum_config['keystone']['admin_password'];
    'DEFAULT/admin_tenant_name':  value => $quantum_config['keystone']['admin_tenant_name'];
    'DEFAULT/nova_metadata_ip':   value => $quantum_config['metadata']['nova_metadata_ip'];
    'DEFAULT/nova_metadata_port': value => $quantum_config['metadata']['nova_metadata_port'];
    'DEFAULT/use_namespaces':     value => $quantum_config['L3']['use_namespaces'];
    'DEFAULT/metadata_proxy_shared_secret': value => $quantum_config['metadata']['metadata_proxy_shared_secret'];
  }

  if $::quantum::params::metadata_agent_package {
    package { 'quantum-metadata-agent':
      name   => $::quantum::params::metadata_agent_package,
      ensure => present,

    }
    # do not move it to outside this IF
    Anchor['quantum-metadata-agent'] ->
      Package['quantum-metadata-agent'] ->
        Quantum_metadata_agent_config<||>
  }

  if $service_provider == 'generic' {
    # non-HA architecture
    service { 'quantum-metadata-agent':
      name    => $::quantum::params::metadata_agent_service,
      enable  => true,
      ensure  => running,
    }

    Anchor['quantum-metadata-agent'] ->
      Quantum_metadata_agent_config<||> ->
        Service['quantum-metadata-agent'] ->
          Anchor['quantum-metadata-agent-done']
  } else {
    # OCF script for pacemaker
    # and his dependences
    file {'quantum-metadata-agent-ocf':
      path=>'/usr/lib/ocf/resource.d/mirantis/quantum-agent-metadata',
      mode => 755,
      owner => root,
      group => root,
      source => "puppet:///modules/quantum/ocf/quantum-agent-metadata",
    }
    Package['pacemaker'] -> File['quantum-metadata-agent-ocf']

    service { 'quantum-metadata-agent__disabled':
      name    => $::quantum::params::metadata_agent_service,
      enable  => false,
      ensure  => stopped,
    }
    Cs_commit <| title == 'ovs' |> -> Cs_shadow <| title == "$res_name" |>

    cs_shadow { $res_name: cib => $cib_name }
    cs_commit { $res_name: cib => $cib_name } ~> ::Corosync::Cleanup["$res_name"]
    ::corosync::cleanup { $res_name: }
    ::Corosync::Cleanup["$res_name"] -> Service[$res_name]

    File<| title=='quantum-logging.conf' |> ->
    cs_resource { "$res_name":
      ensure          => present,
      cib             => $cib_name,
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => 'quantum-agent-metadata',
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
          'timeout'  => '30'
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
      Cs_commit["$res_name"] ->
        ::Corosync::Cleanup["$res_name"] ->
          Service["$res_name"]

    service {"$res_name":
      name       => $res_name,
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      provider   => "pacemaker"
    }

    Anchor['quantum-metadata-agent'] ->
      Quantum_metadata_agent_config<||> ->
        File['quantum-metadata-agent-ocf'] ->
          Service['quantum-metadata-agent__disabled'] ->
            Cs_resource["$res_name"] ->
              Service["$res_name"] ->
                Anchor['quantum-metadata-agent-done']
  }
  anchor {'quantum-metadata-agent-done': }
}

# vim: set ts=2 sw=2 et :