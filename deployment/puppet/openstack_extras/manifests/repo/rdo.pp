# RDO repo
# Supports both RHEL-alikes and Fedora, requires EPEL non-Fedora
#
# === Parameters
# [*release*]
#   The OpenStack release to target. Valid options are 'grizzly',
#   'havana' and 'icehouse'.
#   Defaults to 'icehouse'.
#
class openstack_extras::repo::rdo(
  $release = 'icehouse'
) {

  $supported_releases = [ 'grizzly', 'havana', 'icehouse' ]

  if member($supported_releases, $release) {
    $release_cap = capitalize($release)

    case $::operatingsystem {
      centos, redhat, scientific, slc: {
        $dist = 'epel'
        include ::epel
      }
      fedora: { $dist = 'fedora' }
      default: {
        fail("Unrecognised operatingsystem ${::operatingsystem}")
      }
    }
    # $lsbmajdistrelease is only available with redhat-lsb installed
    $osver = regsubst($::operatingsystemrelease, '(\d+)\..*', '\1')

    yumrepo { 'rdo-release':
      baseurl  => "http://repos.fedorapeople.org/repos/openstack/openstack-${release}/${dist}-${osver}/",
      descr    => "OpenStack ${release_cap} Repository",
      enabled  => 1,
      gpgcheck => 1,
      gpgkey   => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-RDO-${release_cap}",
      priority => 98,
      notify   => Exec['yum_refresh'],
    }
    file { "/etc/pki/rpm-gpg/RPM-GPG-KEY-RDO-${release_cap}":
      source => "puppet:///modules/openstack_extras/RPM-GPG-KEY-RDO-${release_cap}",
      owner  => root,
      group  => root,
      mode   => '0644',
      before => Yumrepo['rdo-release'],
    }
    Yumrepo['rdo-release'] -> Package<||>
  } else {
    fail("${release} is not a supported RDO release. Options are ${supported_releases}.")
  }
}
