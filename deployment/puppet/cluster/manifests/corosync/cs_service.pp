# Not a doc string

# Requirements:
#   * All ocf scripts located in $modulename/files/ocs/$scriptname
#

define cluster::corosync::cs_service (
  $ocf_script,
  $service_name,
  $ocf_vendor = 'mirantis'
  $csr_multistate_hash = undef,
  $csr_ms_metadata = undef,
  $csr_parameters = undef,
  $csr_metadata = undef,
  $csr_mon_intr = 20,
  $csr_mon_timeout = 20,
  $csr_timeout = 60,
  $mangle_real_service = true,
  $service_title = undef,      # Title of Service from community manifests
  $package = false,
  $primary = true,
  $hasrestart = true,
  )
{
  $service_true_title = $service_title ? { undef => $service_name, default => $service_title }

  #fixme: if it's wrong
  $tmp_ocf = split($ocf_script, ':')
  $ocf_module_name = $tmp_ocf[0]
  $ocf_file_name = $tmp_ocf[1]

  # OCF script for pacemaker
  file {$ocf_script:
    path   => "/usr/lib/ocf/resource.d/$ocf_vendor/${ocf_file_name}",
    mode   => '0755',
    owner  => root,
    group  => root,
    source => "puppet:///modules/${ocf_module_name}/ocf/${ocf_file_name}"
  }

  if $primary {
    cs_resource { "p_${service_name}":
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => $ocf_vendor,
      primitive_type  => $ocf_file_name,
      multistate_hash => $csr_multistate_hash,
      ms_metadata     => $csr_ms_metadata,
      parameters      => $csr_parameters,
      metadata        => $csr_metadata,
      #todo: move it as incoming paramerers, because we can have more that one monitor.
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
    Package <| title == $package |> -> Service["${service_name}-disable-init"]
    Service["${service_name}-disable-init"] -> Service["${service_true_title}"]
  }

  # Ubuntu packages like to auto-start, this is annoying and makes it harder
  # to put them under pacemaker. In these cases, we need to inject the
  # override file before the package is installed. When upstart sees this it
  # will cause it to ignore the autostart that the service might of had.
  if $::operatingsystem == 'Ubuntu' and $package {
    file {"/etc/init/${service_name}.override":
      replace => 'no',
      ensure  => present,
      content => 'manual',
      mode    => '0644'
    } -> Package <| title == $package |>
  }

  Service<| title=="${service_true_title}" |> {
    name       => "p_${service_name}",
    enable     => true,
    ensure     => running,
    hasstatus  => true,
    hasrestart => $hasrestart,
    provider   => "pacemaker",
  }
  Service<| title=="${service_name}-disable-init" |> {
    name       => $service_name,
  }
}