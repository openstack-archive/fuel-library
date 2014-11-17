# Not a doc string

#TODO (bogdando) move to extras ha wrappers,
#  remove mangling due to new pcs provider
define cluster::corosync::cs_service (
  $ocf_script,
  $service_name,
  $service_title = undef,  # Title of Service, that been mangled for pacemakering
  $package_name  = undef,
  $csr_complex_type = undef,
  $csr_ms_metadata = undef,
  $csr_parameters = undef,
  $csr_metadata = undef,
  $csr_mon_intr = 20,
  $csr_mon_timeout = 20,
  $csr_timeout = 60,
  $primary = true,
  $hasrestart = true,
  )
{
  $service_true_title = $service_title ? {
    undef => $service_name,
    default => $service_title
  }

  # OCF script for pacemaker
  file { $ocf_script :
    path   => "/usr/lib/ocf/resource.d/mirantis/${ocf_script}",
    mode   => '0755',
    owner  => root,
    group  => root,
    source => "puppet:///modules/cluster/ocf/${ocf_script}"
  }

  if $primary {
    cs_resource { "p_${service_name}":
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => $ocf_script,
      complex_type    => $csr_complex_type,
      ms_metadata     => $csr_ms_metadata,
      parameters      => $csr_parameters,
      metadata        => $csr_metadata,
      operations      => {
        'monitor' => {
          'interval' => $csr_mon_intr,
          'timeout'  => $csr_mon_timeout
        },
        'start'   => {
          'timeout' => $csr_timeout
        },
        'stop'    => {
          'timeout' => $csr_timeout
        }
      }
    }
    File[$ocf_script] -> Cs_resource["p_${service_name}"] -> Service[$service_true_title]
  } else {
    File[$ocf_script] -> Service[$service_true_title]
  }

  if ! $package_name {
    warning('Cluster::corosync::cs_service: Without package definition can\'t protect service for autostart correctly.')
  } else {
    tweaks::ubuntu_service_override { "${service_name}":
      package_name => $package_name,
    }
  }

  Service<| title=="${service_true_title}" |> {
    enable     => true,
    ensure     => running,
    hasstatus  => true,
    hasrestart => $hasrestart,
    provider   => 'pacemaker',
  }
}
