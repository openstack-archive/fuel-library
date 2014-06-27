# Not a doc string

define cluster::corosync::cs_service (
  $ocf_script,
  $service_name,
  $csr_multistate_hash = undef,
  $csr_ms_metadata = undef,
  $csr_parameters = undef,
  $csr_metadata = undef,
  $csr_mon_intr = 20,
  $csr_mon_timeout = 20,
  $csr_timeout = 60,
  $real_service = undef,
  )
{
  # OCF script for pacemaker
  # and his dependences
  file {$ocf_script:
    path   => "/usr/lib/ocf/resource.d/mirantis/${ocf_script}",
    mode   => '0755',
    owner  => root,
    group  => root,
    source => "puppet:///modules/neutron/ocf/${ocf_script}",
  } ->

  cs_resource { $service_name:
    ensure          => present,
    primitive_class => 'ocf',
    provided_by     => 'mirantis',
    primitive_type  => $ocf_script,
    multistate_hash => $csr_multistate_hash,
    ms_metadata     => $csr_ms_metadata,
    parameters      => $csr_parameters,
    metadata        => $csr_metadata,
    operations      => {
      'monitor'  => {
        'interval' => $csr_mon_intr,
        'timeout'  => $csr_mon_timeout
      }
      ,
      'start'    => {
        'timeout' => $csr_timeout
      }
      ,
      'stop'     => {
        'timeout' => $csr_timeout
      }
    },
  }

  if $real_service {
    # If we have a real service, then we need to disable it. Some service
    # manifests will do this for us (which is preferred)
    service { "${service_name}-disable-init":
      name       => $real_service,
      enable     => false,
      ensure     => stopped,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::neutron::params::service_provider,
      before     => Service["p_$service_name"]
    }
  }

  service { "p_${service_name}":
    name       => $service_name,
    enable     => true,
    ensure     => running,
    hasstatus  => true,
    hasrestart => false,
    provider   => "pacemaker",
    require    => Cs_resource[$service_name]
  }

}