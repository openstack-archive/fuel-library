define swift::ringsync(
  $ring_server
) {
  if ! defined (Anchor['swift_ringsync_start']) {
    anchor{'swift_ringsync_start':}
  }
  Anchor['swift_ringsync_start']->
  rsync::get { "/etc/swift/${name}.ring.gz":
    source  => "rsync://${ring_server}/swift_server/${name}.ring.gz",
  }->
  Anchor['swift_ringsync_end']

  if ! defined (Anchor['swift_ringsync_end']) {
    anchor{'swift_ringsync_end':}
  }
}
