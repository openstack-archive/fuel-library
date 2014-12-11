# Shared functions
def filter_nodes(hash, name, value)
  hash.select do |it|
    it[name] == value
  end
end

def nodes_to_hash(hash, name, value)
  result = {}
  hash.each do |element|
    result[element[name]] = element[value]
  end
  return result
end

def ipsort (ips)
  require 'rubygems'
  require 'ipaddr'
  sorted_ips = ips.sort { |a,b| IPAddr.new( a ) <=> IPAddr.new( b ) }
  return sorted_ips
end

def test_ubuntu_and_centos(manifest)
  # check if task is present in the task list
  unless Noop.manifest_present? manifest
    # puts "Manifest '#{manifest}' is not enabled on the node '#{Noop.hostname}'. Skipping tests."
    return
  end

  # set manifest file
  before(:all) { Noop.set_manifest manifest }

  #######################################
  # Testing on different operating systems
  # Ubuntu
  context 'on Ubuntu platforms' do
    let(:facts) { Noop.ubuntu_facts }
    it_behaves_like 'puppet catalogue'
  end

  # CentOS
  context 'on CentOS platforms' do
    let(:facts) { Noop.ubuntu_facts }
    it_behaves_like 'puppet catalogue'
  end
end

