include cluster 

cluster::virtual_ip { 'xxx':
  vip => {
      nic    => 'eth0', 
      ip     => '10.1.1.253'
  }
}