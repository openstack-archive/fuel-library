class openstack::apparmor::disable ()
{

 exec {'disable_apparmor':
    onlyif => "dpkg -l | grep apparmor",
    command => "dpkg -P apparmor; rm -rf /etc/apparmor /etc/apparmor.d",
    path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    }
}

