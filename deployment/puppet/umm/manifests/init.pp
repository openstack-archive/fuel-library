

class umm (
)

{

    if $::osfamily == 'Redhat' {
        if $::operatingsystemmajrelease == '6' {

            class { 'umm::common':
                release         => 'rh6',
            }

            file { 'umm_svc.rh6':
                ensure          => present,
                source          => 'puppet:///modules/umm/umm_svc.rh6',
                path            => '/usr/lib/umm/umm_svc.rh6',
                owner           => 'root',
                group           => 'root',
                mode            => '0770',
                require         => File['ummlib'],
            }

            file { 'umm-install.sh':
                source          => 'puppet:///modules/umm/umm-install.rh6',
                path            => '/tmp/umm-install.sh',
                owner           => 'root',
                group           => 'root',
                mode            => '0770',
            }

            exec { 'umm-install':
                command         => '/tmp/umm-install.sh',
                require         => File['umm-install.sh'],
                path            => ['/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
                refreshonly     => false,
            }
        }

    }

    if  $::operatingsystem == 'ubuntu' {
        if $::operatingsystemrelease == '14.04' {

            class { 'umm::common':
                release         => 'u1404',
            }

            file { 'umm_svc.u1404':
                ensure          => present,
                source          => 'puppet:///modules/umm/umm_svc.u1404',
                path            => '/usr/lib/umm/umm_svc.u1404',
                owner           => 'root',
                group           => 'root',
                mode            => '0770',
                require         => File['ummlib'],
            }

            file { 'umm-install.sh':
                source          => 'puppet:///modules/umm/umm-install.u1404',
                path            => '/tmp/umm-install.sh',
                owner           => 'root',
                group           => 'root',
                mode            => '0770',
            }

            exec { 'umm-install':
                command         => '/tmp/umm-install.sh',
                require         => File['umm-install.sh'],
                path            => ['/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
                refreshonly     => false,
            }

        }

    }

}
