# == Class: cinder::quota
#
# Setup and configure Cinder quotas.
#
# === Parameters
#
# [*quota_volumes*]
#   (optional) Number of volumes allowed per project. Defaults to 10.
#
# [*quota_snapshots*]
#   (optional) Number of volume snapshots allowed per project. Defaults to 10.
#
# [*quota_gigabytes*]
#   (optional) Number of volume gigabytes (snapshots are also included)
#   allowed per project. Defaults to 1000.
#
# [*quota_driver*]
#   (optional) Default driver to use for quota checks.
#   Defaults to 'cinder.quota.DbQuotaDriver'.
#
class cinder::quota (
  $quota_volumes = 10,
  $quota_snapshots = 10,
  $quota_gigabytes = 1000,
  $quota_driver = 'cinder.quota.DbQuotaDriver'
) {

  cinder_config {
    'DEFAULT/quota_volumes':   value => $quota_volumes;
    'DEFAULT/quota_snapshots': value => $quota_snapshots;
    'DEFAULT/quota_gigabytes': value => $quota_gigabytes;
    'DEFAULT/quota_driver':    value => $quota_driver;
  }
}
