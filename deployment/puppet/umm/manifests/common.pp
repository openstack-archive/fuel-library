
class umm::common (
    $release,
)

{
    file { 'umm.conf':
        ensure  => present,
        source  => 'puppet:///modules/umm/umm.conf',
        path    => '/etc/umm.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0660',
    }

    file { 'issue.mm':
        ensure  => present,
        source  => 'puppet:///modules/umm/issue.mm',
        path    => '/etc/issue.mm',
        owner   => 'root',
        group   => 'root',
        mode    => '0770',
        }

    file { 'ummvar':
        ensure  => directory,
        path    => '/var/lib/umm',
        }

    file { 'ummlib':
        ensure  => directory,
        path    => '/usr/lib/umm',
        require => File['ummvar'],
        }

    file { 'umm_svc':
        ensure  => present,
        source  => 'puppet:///modules/umm/umm_svc',
        path    => '/usr/lib/umm/umm_svc',
        owner   => 'root',
        group   => 'root',
        mode    => '0770',
        require => File['ummlib']
        }


    file { 'umm_vars':
        ensure  => present,
        content => template('umm/umm_vars.erb'),
        path    => '/usr/lib/umm/umm_vars',
        owner   => 'root',
        group   => 'root',
        mode    => '0770',
        require => File['ummlib']
        }

    file { 'umm':
        ensure  => present,
        source  => 'puppet:///modules/umm/umm',
        path    => '/usr/local/bin/umm',
        owner   => 'root',
        group   => 'root',
        mode    => '0770',
        }

    file { 'umm.sh':
        ensure  => present,
        source  => 'puppet:///modules/umm/umm.sh',
        path    => '/etc/profile.d/umm.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0770',
        }

    file { 'umm-br.conf':
        ensure  => present,
        source  => 'puppet:///modules/umm/umm-br.conf',
        path    => '/etc/init/umm-br.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0660',
        }

    file { 'umm-console.conf':
        ensure  => present,
        source  => 'puppet:///modules/umm/umm-console.conf',
        path    => '/etc/init/umm-console.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0660',
        }

    file { 'umm-run.conf':
        ensure  => present,
        source  => 'puppet:///modules/umm/umm-run.conf',
        path    => '/etc/init/umm-run.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0660',
        }

    file { 'umm-tr.conf':
        ensure  => present,
        source  => 'puppet:///modules/umm/umm-tr.conf',
        path    => '/etc/init/umm-tr.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0660',
        }
}

