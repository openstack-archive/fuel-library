define swift::ringsync(
  $ring_server
) {

  Exec { path => '/usr/bin' }

  rsync::get { "/etc/swift/${name}.ring.gz":
    source  => "rsync://${ring_server}/swift_server/${name}.ring.gz",
  }

  rsync::get { "/etc/swift/${name}.builder":
    source  => "rsync://${ring_server}/swift_server/${name}.builder",
  }
}
