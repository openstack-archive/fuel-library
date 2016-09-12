class osnailyfacter::plugins::plugins_rsync {

  notice('MODULAR: plugins/plugins_rsync.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $plugins    = hiera('plugins', {})
  $rsync_data = generate_plugins_rsync($plugins)

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  if ! empty($rsync_data) {
    file { '/etc/fuel/plugins/':
      ensure => directory,
    }

    create_resources(rsync::get, $rsync_data)
  }

  File <| |> -> Rsync::Get <| |>
}
