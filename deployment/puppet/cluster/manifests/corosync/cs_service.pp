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
  # Mask services which are managed by pacemaker
  # LP #1652748
  $mask_service = true,
  )
{
  $service_true_title = $service_title ? {
    undef => $service_name,
    default => $service_title
  }

  if $primary {
    pcmk_resource { "p_${service_true_title}":
      ensure             => 'present',
      primitive_class    => 'ocf',
      primitive_provider => 'fuel',
      primitive_type     => $ocf_script,
      complex_type       => $csr_complex_type,
      complex_metadata   => $csr_ms_metadata,
      parameters         => $csr_parameters,
      metadata           => $csr_metadata,
      name               => $service_name,
      operations         => {
        'monitor'        => {
          'interval'     => $csr_mon_intr,
          'timeout'      => $csr_mon_timeout
        },
        'start'   => {
          'interval' => '0',
          'timeout'  => $csr_timeout
        },
        'stop'    => {
          'interval' => '0',
          'timeout'  => $csr_timeout
        }
      }
    }
    Pcmk_resource["p_${service_true_title}"] -> Service<| title == $service_true_title |>
  }
  if ! $package_name {
    warning('Cluster::corosync::cs_service: Without package definition can\'t protect service for autostart correctly.')
  } else {
    tweaks::ubuntu_service_override { "${service_name}":
      package_name => $package_name,
      mask_service => $mask_service,
    } -> Service<| title=="${service_true_title}" |>
  }

  Service<| title=="${service_true_title}" |> {
    name     => $service_name,
    provider => 'pacemaker',
  }
}
