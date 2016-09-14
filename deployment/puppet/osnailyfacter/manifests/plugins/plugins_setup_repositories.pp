class osnailyfacter::plugins::plugins_setup_repositories {

  notice('MODULAR: plugins/plugins_setup_repositories.pp')

  $plugins = hiera('plugins')

  if $::osfamily == 'Debian' {
    include ::apt

    $repositories = generate_plugins_repos($plugins)
    $repositories_w_prios = generate_plugins_repos($plugins, true)
    $pins = generate_plugins_pins($repositories_w_prios)

    if ! empty($repositories) {
      create_resources(apt::source, $repositories)
    }

    if !empty($pins)
    {
      create_resources(apt::pin, $pins)
    }

  }

}
