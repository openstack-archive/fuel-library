# Ubuntu Cloud Archive Repository
#
# === parameters
#
# [*release*]
#   The OpenStack release. Supported options are
#   'folsom', 'grizzly', 'havana', and 'icehouse'.
#   Default is 'icehouse'.
#
# [*repo*]
#   The UCS repository to pull from. Current supported
#   options are 'proposed' and 'updates'.
#   Default is 'updates'.
class openstack_extras::repo::uca(
  $release         = 'icehouse',
  $repo            = 'updates',
  $exec_apt_update = true
) {

  $supported_releases = ['folsom', 'grizzly', 'havana', 'icehouse']

  if member($supported_releases, $release) {
    if ($::operatingsystem == 'Ubuntu' and
        $::lsbdistdescription =~ /^.*12\.04.*LTS.*$/) {
      include apt::update

      apt::source { 'ubuntu-cloud-archive':
        location          => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
        release           => "${::lsbdistcodename}-${repo}/${release}",
        repos             => 'main',
        required_packages => 'ubuntu-cloud-keyring',
      }

      Exec['apt_update'] -> Package<||>
    }
  } else {
    fail("${release} is not a supported UCA release. Options are ${supported_releases}.")
  }
}
