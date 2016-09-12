class osnailyfacter::plugins::plugins_rsync {

  notice('MODULAR: plugins/plugins_rsync.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  $plugins    = hiera('plugins', {})
  $rsync_data = generate_plugins_rsync($plugins)

  if ! empty($rsync_data) {
    file { '/etc/fuel/plugins/':
      ensure => directory,
    }

    create_resources(rsync::get, $rsync_data)
  }

  File <| |> -> Rsync::Get <| |>
}
