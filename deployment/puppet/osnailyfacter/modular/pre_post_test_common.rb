require 'hiera'
require 'test/unit'
require 'open-uri'

def hiera
  return $hiera if $hiera
  $hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
end

def management_vip
  return $management_vip if $management_vip
  $management_vip = hiera.lookup 'management_vip', nil, {}
end

def controller_node_address
  return $controller_node_address if $controller_node_address
  $controller_node_address = hiera.lookup 'controller_node_address', nil, {}
end

###############################################################################

def haproxy_stats_url
  ip = management_vip
  ip = controller_node_address unless ip
  raise 'Could not get internal address!' unless ip
  port = 10000
  "http://#{ip}:#{port}/;csv"
end

def csv
  return $csv if $csv
  begin
    url = open(haproxy_stats_url)
    csv = url.read
  rescue
    nil
  end
  return nil unless csv and not csv.empty?
  $csv = csv
end

def haproxy_backends
  return $backends if $backends
  raise 'Could not get CSV from HAProxy stats!' unless csv
  backends = {}
  csv.split("\n").each do |line|
    next if line.start_with? '#'
    next unless line.include? 'BACKEND'
    fields = line.split(',')
    backend = fields[0]
    status = fields[17]
    backends[backend] = status
  end
  $backends = backends
end

def haproxy_backend_present?(backend)
  haproxy_backends.keys.include? backend
end

def haproxy_backend_up?(backend)
  haproxy_backends[backend] == 'UP'
end

###############################################################################

def process_list
  return $process_list if $process_list
  $process_list = []
  ps = `ps haxo cmd`
  ps.split("\n").each do |cmd|
    $process_list << cmd
  end
  $process_list
end

def process_running?(process)
  process_list.find { |cmd| cmd.include? process }
end

def process_tree
  return $process_tree if $process_tree
  $process_tree = {}
  ps = `ps haxo pid,ppid,cmd`
  ps.split("\n").each do |p|
    f = p.split
    pid = f.shift.to_i
    ppid = f.shift.to_i
    cmd = f.join ' '

    # create entry for this pid if not present
    $process_tree[pid] = {
        :children => []
    } unless $process_tree.key? pid

    # fill this entry
    $process_tree[pid][:ppid] = ppid
    $process_tree[pid][:pid] = pid
    $process_tree[pid][:cmd] = cmd

    unless ppid == 0
      # create entry for parent process if not present
      $process_tree[ppid] = {
          :children => [],
          :cmd => '',
      } unless $process_tree.key? ppid

      # fill parent's children
      $process_tree[ppid][:children] << pid
    end
  end
  $process_tree
end
