class nailgun::mcollective
{
  include stdlib

  ensure_packages('fuel-agent')
  ensure_packages('fuel-provisioning-scripts')
  ensure_packages('shotgun')
  ensure_packages('fuel-agent-bootstrap-ironic-configs')
  ensure_packages ('fuel-bootstrap-image-builder')
}
