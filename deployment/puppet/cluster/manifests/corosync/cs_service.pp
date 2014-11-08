# Not a doc string

define cluster::corosync::cs_service (
  $ocf_script,
  $service_name,
  $service_title = undef,  # Title of Service, that been mangled for pacemakering
  $package_name  = undef,
  $csr_multistate_hash = undef,
  $csr_ms_metadata = undef,
  $csr_parameters = undef,
  $csr_metadata = undef,
  $csr_mon_intr = 20,
  $csr_mon_timeout = 20,
  $csr_timeout = 60,
  $mangle_real_service = true,
  $primary = true,
  $hasrestart = true,
  )
{
  $service_true_title = $service_title ? {
    undef => $service_name,
    default => $service_title
  }

  # OCF script for pacemaker
  file {$ocf_script:
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
      multistate_hash => $csr_multistate_hash,
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
    File["$ocf_script"] -> Cs_resource["p_${service_name}"] -> Service["${service_true_title}"]
  } else {
    File["$ocf_script"] -> Service["${service_true_title}"]
  }

  if $mangle_real_service {
    # If the service is defined elsewhere, then we need to disable it. Some
    # service manifests will do this for us (which is preferred)
    service { "${service_name}-disable-init":
      name       => "${service_name}-disable-init",  # this will be redefined later
      enable     => false,
      ensure     => stopped,
      hasstatus  => true,
      hasrestart => true
    }
    Service["${service_name}-disable-init"] -> Service["${service_true_title}"]

    # In this IF used Package[$package_name] notation, because $package_name incoming parameter may be array.
    if ! $package_name {
      warning("Cluster::cs_service: Without package definition can't mangle service correctly.")
    } else {
      if $::operatingsystem == 'Ubuntu' {
        # Ubuntu packages like to auto-start, this is annoying and makes it harder
        # to put them under pacemaker. In these cases, we need to inject the
        # override file before the package is installed. When upstart sees this it
        # will cause it to ignore the autostart that the service might of had.
        file {"/etc/init/${service_name}.override":
          replace => 'no',
          ensure  => present,
          content => 'manual',
          mode    => '0644'
        }
        File["/etc/init/${service_name}.override"] -> Package[$package_name]
      }
      # Service SHOULD be found just by spaceship operation
      Package[$package_name] -> Service<| title == "${service_name}-disable-init" |>
    }
  }

  Service<| title=="${service_true_title}" |> {
    name       => "p_${service_name}",
    enable     => true,
    ensure     => running,
    hasstatus  => true,
    hasrestart => $hasrestart,
    provider   => "pacemaker",
  }
  # This here, because it should be found AFTER previous Service.
  # DO NOT change this order, or put this under any IF
  Service<| title=="${service_name}-disable-init" |> {
    name       => $service_name,
  }
}
