define pacemaker_wrappers::service (
  $ensure              = 'present',
  $ocf_root_path       = '/usr/lib/ocf',
  $primitive_class     = 'ocf',
  $primitive_provider  = 'mirantis',
  $primitive_type      = undef,

  $parameters          = undef,
  $operations          = undef,
  $metadata            = undef,
  $ms_metadata         = undef,
  $complex_type        = undef,

  $use_handler         = true,
  $handler_root_path   = '/usr/local/bin',

  $ocf_script_template = undef,
  $ocf_script_file     = undef,

  $create_primitive    = true,
  $cib                 = undef,
) {

  $service_name     = $title
  $primitive_name   = "p_${service_name}"
  $ocf_script_name  = "${service_name}-ocf-file"
  $ocf_handler_name = "ocf_handler_${service_name}"

  $ocf_dir_path     = "${ocf_root_path}/resource.d"
  $ocf_script_path  = "${ocf_dir_path}/${primitive_provider}/${$primitive_type}"
  $ocf_handler_path = "${handler_root_path}/${ocf_handler_name}"

  Service<| title == $service_name |> {
    provider   => 'pacemaker',
  }

  Service<| name == $service_name |> {
    provider   => 'pacemaker',
  }

  if $create_primitive {
    cs_resource { $primitive_name :
      ensure          => $ensure,
      primitive_class => $primitive_class,
      primitive_type  => $primitive_type,
      provided_by     => $primitive_provider,
      parameters      => $parameters,
      operations      => $operations,
      metadata        => $metadata,
      ms_metadata     => $ms_metadata,
      complex_type    => $complex_type,
    }
  }

  if $ocf_script_template or $ocf_script_file {
    file { $ocf_script_name :
      ensure  => $ensure,
      path    => $ocf_script_path,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
    }

    if $ocf_script_template {
      File[$ocf_script_name] {
        content => template($ocf_script_template),
      }
    } elsif $ocf_script_file {
      File[$ocf_script_name] {
        source => "puppet:///modules/${ocf_script_file}",
      }
    }

  }

  if ($primitive_class == 'ocf') and ($use_handler) {
    file { $ocf_handler_name :
      path    => $ocf_handler_path,
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      content => template('pacemaker_wrappers/ocf_handler.erb'),
    }
  }

  File<| title == $ocf_script_name |> -> Cs_resource<| title == $primitive_name |>
  File<| title == $ocf_script_name |> ~> Service[$service_name]
  Cs_resource<| title == $primitive_name |> -> Service[$service_name]
  File<| title == $ocf_handler_name |> -> Service[$service_name]

}
