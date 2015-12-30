class nailgun::mcollective
{
  include stdlib
  $packages = [
    'fuel-agent',
    'fuel-provisioning-scripts',
    'shotgun',
    'ironic-fa-bootstrap-configs',
    'fuel-bootstrap-cli'
  ]
  ensure_packages($packages)
}
