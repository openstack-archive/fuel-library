class osnailyfacter::plugins::plugins_rsync {

  notice('MODULAR: plugins/plugins_rsync.pp')

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
