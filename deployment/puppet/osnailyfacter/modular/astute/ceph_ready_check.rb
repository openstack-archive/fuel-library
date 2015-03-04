#!/usr/bin/env ruby
require 'json'
require 'hiera'

ENV['LANG'] = 'C'
$hiera = Hiera.new(:config => '/etc/hiera.yaml')

def ceph(args)
  stdout = `ceph -f json #{args}`
  return JSON.parse(stdout) if $?.exitstatus == 0
  return false
end

def ready_ceph
  ceph_health = `ceph health`
  (warn 'ceph failed'; return false ) if $?.exitstatus != 0
  return true if ceph_health.include? 'HEALTH_OK'
  if ceph_health.include? 'HEALTH_ERR'
    puts "Ceph cluster health is in error "
    return false
  end
  #Getting the pool size
  pool_size = $hiera.lookup('storage', false, {})['osd_pool_size'].to_i
  #Getting the number of ceph osds, which are in cluster and in up state
  osd_stat = ceph('osd stat')
  osds_up = osd_stat['num_up_osds']
  osds_in = osd_stat['num_in_osds']
  if (osds_up <= pool_size) or (osds_in <= pool_size)
    puts "OSDs in cluster less than pool size: Pool size #{pool_size} UP #{osds_up} IN #{osds_in}"
    return false
  end
  #Check whether every OSD has the same upstate and instate
  osd_dump = ceph('osd dump')
  osd_dump['osds'].each do |osd_id|
    if osd_id['up'] != osd_id['in']
      puts "The osd.#{osd_id['osd']} is in bad state: instate #{osd_id['in']} upstate #{osd_id['up']} !"
      return false
    end
  end
  #Check whether every pg has correct state
  pg_dump = ceph('pg dump')
  pg_dump['pg_stats'].each do |pg_id|
    if !pg_id['state'].match(/^active\+/)
      puts "The pgid #{pg_id['pgid']} is in bad state #{pg_id['state']} !"
      return false
    end
  end
end

# check if ceph cluster is ready
def wait_for_ready_ceph
  180.times do |try|
    puts "try #{try}"
    return if ready_ceph
    sleep 10
  end
  raise 'Ceph is not ready yet!
Please check the status of ceph cluster manually.'
end

wait_for_ready_ceph

