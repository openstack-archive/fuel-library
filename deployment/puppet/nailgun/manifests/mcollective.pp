class nailgun::mcollective
{
  include stdlib

  ensure_packages('fuel-agent')
  ensure_packages('fuel-provisioning-scripts')
  ensure_packages('shotgun')
}
