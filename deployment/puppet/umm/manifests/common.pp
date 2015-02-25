
class umm::common (
    $release,
)

{
    file { 'umm.conf':
        path    => '/etc/umm.conf',
        content => template("umm/umm.conf.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0660',
        ensure  => present,
    }

    file { 'issue.mm':
        source  => 'puppet:///modules/umm/issue.mm',
        path    => '/etc/issue.mm',
        owner   => 'root',
        group   => 'root',
        mode    => '0770',
        ensure  => present,
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
        source  => 'puppet:///modules/umm/umm_svc',
        path    => '/usr/lib/umm/umm_svc',
        owner   => 'root',
        group   => 'root',
        mode    => '0770',
        ensure  => present,
        require => File['ummlib']
        }


    file { 'umm_vars':
        source  => 'puppet:///modules/umm/umm_vars',
        path    => '/usr/lib/umm/umm_vars',
        owner   => 'root',
        group   => 'root',
        mode    => '0770',
        ensure  => present,
        require => File['ummlib']
        }

    file { 'umm':
        source  => 'puppet:///modules/umm/umm',
        path    => '/usr/local/bin/umm',
        owner   => 'root',
        group   => 'root',
        mode    => '0770',
        ensure  => present,
        }

    file { 'umm.sh':
        source  => 'puppet:///modules/umm/umm.sh',
        path    => '/etc/profile.d/umm.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0770',
        ensure  => present,
        }

    file { 'umm-br.conf':
        source  => 'puppet:///modules/umm/umm-br.conf',
        path    => '/etc/init/umm-br.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0660',
        ensure  => present,
        }

    file { 'umm-console.conf':
        source  => 'puppet:///modules/umm/umm-console.conf',
        path    => '/etc/init/umm-console.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0660',
        ensure  => present,
        }

    file { 'umm-run.conf':
        source  => 'puppet:///modules/umm/umm-run.conf',
        path    => '/etc/init/umm-run.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0660',
        ensure  => present,
        }

    file { 'umm-tr.conf':
        source  => 'puppet:///modules/umm/umm-tr.conf',
        path    => '/etc/init/umm-tr.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0660',
        ensure  => present,
        }
}

