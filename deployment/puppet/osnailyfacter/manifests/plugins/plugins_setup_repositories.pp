class osnailyfacter::plugins::plugins_setup_repositories {

  notice('MODULAR: plugins/plugins_setup_repositories.pp')

  $plugins = hiera('plugins')

  if $::osfamily == 'Debian' {
    include ::apt

    $repositories = generate_plugins_repos($plugins)

    if ! empty($repositories) {
      create_resources(apt::source, $repositories)
    }

  }

}
