#!/usr/bin/env ruby
require 'rubygems'
require 'hiera'
require 'timeout'

HIERA_CONFIG  = '/etc/puppet/hiera.yaml'
DEFAULT_COROSYNC_ROLES = %w(controller primary-controller)

RETRY_COUNT   = 5
RETRY_WAIT    = 1
RETRY_TIMEOUT = 10

def hiera
  return $hiera if $hiera
  $hiera = Hiera.new(:config => HIERA_CONFIG)
  Hiera.logger = "noop"
  $hiera
end

def nodes
  network_metadata = hiera.lookup 'network_metadata', {}, {}, nil, :hash
  nodes_hash = network_metadata['nodes']
  raise 'Invalid nodes data!' unless nodes_hash.is_a? Hash
  nodes_hash
end

def corosync_roles
  return $corosync_roles if $corosync_roles
  $corosync_roles = hiera.lookup 'corosync_roles', DEFAULT_COROSYNC_ROLES, {}, nil, :priority
  raise 'Invalid corosync_roles!' unless $corosync_roles.is_a? Array
  $corosync_roles
end

def corosync_tags
  return $corosync_tags if $corosync_tags
  $corosync_tags = hiera.lookup 'corosync_tags', [], {}, nil, :priority
  raise 'Invalid corosync_tags!' unless $corosync_tags.is_a? Array
  $corosync_tags
end

def corosync_nodes_count
  return $corosync_nodes_count if $corosync_nodes_count
  $corosync_nodes = nodes.select do |key, node|
    (corosync_roles & node['node_roles'] || corosync_tags & node.fetch('node_tags')).any?
  end.size
end

def set_quorum_policy(value)
  puts "Setting no-quorum-policy to: '#{value}'"
  RETRY_COUNT.times do |n|
    begin
      Timeout::timeout(RETRY_TIMEOUT) do
        system "crm_attribute --verbose --type crm_config --name no-quorum-policy --update #{value}"
        return if $?.exitstatus == 0
      end
    rescue Timeout::Error
      nil
    end
    puts "Error! Retry: #{n + 1}"
    sleep RETRY_WAIT
  end
  fail "Could not set no-quorum-policy to: '#{value}'!"
end

def get_quorum_policy
  RETRY_COUNT.times do |n|
    begin
      Timeout::timeout(RETRY_TIMEOUT) do
        policy = `crm_attribute --type crm_config --name no-quorum-policy --query --quiet`.chomp
        return policy if $?.exitstatus == 0
      end
    rescue Timeout::Error
      nil
    end
    puts "Error! Retry: #{n + 1}"
    sleep RETRY_WAIT
  end
  fail "Could not get no-quorum-policy!"
end

##############

puts "Corosync nodes found: '#{corosync_nodes_count}'"

if corosync_nodes_count > 2
  set_quorum_policy 'stop' unless get_quorum_policy == 'stop'
else
  set_quorum_policy 'ignore' unless get_quorum_policy == 'ignore'
end

puts "Current no-quorum-policy is: '#{get_quorum_policy}'"
exit 0
