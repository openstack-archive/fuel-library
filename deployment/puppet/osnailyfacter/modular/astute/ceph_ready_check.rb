#!/usr/bin/env ruby
require 'hiera'

ENV['LANG'] = 'C'

hiera = Hiera.new(:config => '/etc/hiera.yaml')

def ready_ceph
  # Getting the pool size
  pool_size_output = `grep osd_pool_default_size /etc/ceph/ceph.conf`
  return false if $?.exitstatus != 0
  pool_size = pool_size_output.split('=')[1].to_i
  #Getting the number of ceph osds, which are in cluster
  osds_in_out = `ceph osd stat`
  return false if $?.exitstatus != 0
  osds_in = osds_in_out.split('osds:')[1].split(',')[1].split(' ')[0].to_i
  #Check whether placement group is in active state
  active_pg = false
  active_pg_o = `ceph pg stat | grep -q active`
  active_pg = true if $?.exitstatus == 0
  #If we have enough osds in cluster and the placement group is in ready state then we can use ceph
  #http://ceph.com/docs/master/rados/operations/monitoring-osd-pg/
  return true  if osds_in >= pool_size and active_pg
  false
end

# check if ceph cluster is ready
def wait_for_ready_ceph
  180.times.each do |retries|
    return if ready_ceph
    sleep 10
  end
  raise 'Ceph is not ready yet!'
end

storage_hash = hiera.lookup('storage', false, {})

wait_for_ready_ceph if storage_hash['images_ceph'] or storage_hash['volumes_ceph'] or storage_hash['objects_ceph'] or storage_hash['ephemeral_ceph']
