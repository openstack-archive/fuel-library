class l23network::hosts_file ($hosts,$hosts_file="/etc/hosts") {

#Move original hosts file

$hosts=nodes_to_hosts($nodes)
Host {
    ensure   => present,
    target => $hosts_file
}
notify{"$hosts":}
create_resources(host,$hosts)
}


