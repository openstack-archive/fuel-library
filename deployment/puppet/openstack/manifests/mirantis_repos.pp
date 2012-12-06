class openstack::mirantis_repos (
  # DO NOT change this value to 'internal'. all our customers are relying on external repositories
  $type        = 'external'
) {
    case $::osfamily {
      'Debian': {
        class { 'apt':
          stage => 'openstack-custom-repo',
          always_apt_update => true,
        } #->
#     Currently we use only standard Debian repos, installed with OS
#     There is nothing in our custom repo for Debian.
#        class { 'openstack::repo::apt':
#          key => '420851BC',
#          location => 'http://172.18.66.213/deb',
#          key_source => 'http://172.18.66.213/gpg.pub',
#          origin => '172.18.66.213',
#          stage => 'openstack-custom-repo',
#        }
      }
      'RedHat': {
        #added internal/external network mirror
        $mirrorlist="http://download.mirantis.com/epel-fuel/mirror.$type.list"
        class { 'openstack::repo::yum':
          repo_name  => 'openstack-epel-fuel',
          mirrorlist => $mirrorlist,
          key_source => "http://download.mirantis.com/epel-fuel/centos.key\n  http://download.mirantis.com/epel-fuel/epel.key\n http://download.mirantis.com/epel-fuel/rabbit.key\n http://download.mirantis.com/epel-fuel/mirantis.key\n http://download.mirantis.com/epel-fuel/mysql.key",
          stage      => 'openstack-custom-repo',
        }
      }
      default: {
        fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
      }
    }
}

