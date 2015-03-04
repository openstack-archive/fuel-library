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
  return false if !(ceph_health = ceph('health')['overall_status'])
  return true if ceph_health.include? 'HEALTH_OK'
  if ceph_health.include? 'HEALTH_ERR'
    puts "Ceph cluster health is in error!"
    return false
  end
  #Getting the pool size
  pool_size = $hiera.lookup('storage', false, {})['osd_pool_size'].to_i
  #Getting the number of ceph osds, which are in cluster and in up state
  return false if !(osd_stat = ceph('osd stat'))
  osds_up = osd_stat['num_up_osds']
  osds_in = osd_stat['num_in_osds']
  if (osds_up <= pool_size) or (osds_in <= pool_size)
    puts "OSDs in cluster less than pool size: Pool size #{pool_size} UP #{osds_up} IN #{osds_in}"
    return false
  end
  #Check whether every OSD wich is in state also and in up state
  return false if !(osd_dump = ceph('osd dump')['osds'])
  osd_dump.each do |osd_id|
    if ( osd_id['in'] == 1 and osd_id['up'] == 0 )
      puts "The osd.#{osd_id['osd']} is in bad state: instate #{osd_id['in']} upstate #{osd_id['up']} !"
      return false
    end
  end
  #Check whether every pg has correct state
  return false if !(pg_dump = ceph('pg dump')['pg_stats'])
  pg_dump.each do |pg_id|
    if !pg_id['state'].match(/^active\+/)
      puts "The pgid #{pg_id['pgid']} is in bad state #{pg_id['state']} !"
      return false
    end
  end
  return true
end

# check if ceph cluster is ready
def wait_for_ready_ceph
  170.times do |try|
    puts "try #{try}"
    return if ready_ceph
    sleep 10
  end
  raise 'Ceph is not ready yet!
Please check the status of ceph cluster manually.'
end

wait_for_ready_ceph
