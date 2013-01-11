class ssh::knownhosts {
    Sshkey <<| tag == "${::deployment_id}::${::environment}" |>> {
        ensure => present,
    }
}
