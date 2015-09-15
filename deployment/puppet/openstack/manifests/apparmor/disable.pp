class openstack::apparmor::disable ()
{

  exec {'disable_apparmor':
    onlyif => "dpkg -l | grep -w apparmor",
    command => "invoke-rc.d apparmor teardown && apt-get purge -y apparmor && rm -rf /etc/apparmor /etc/apparmor.d",
    path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    }
}

