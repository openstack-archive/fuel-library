class mongodb::firewall (
  $mongodb_port = 27017,
)

{
  firewall {'120 mongodb':
    port => $mongodb_port,
    proto => 'tcp',
    action => 'accept',
  }
}
