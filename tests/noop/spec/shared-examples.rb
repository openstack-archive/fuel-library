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

  shared_examples 'should_compile' do
    it {
      File.stubs(:exists?).with('/var/lib/astute/ceph/ceph').returns(true)
      File.stubs(:exists?).with('/var/lib/astute/mongodb/mongodb.key').returns(true)
      File.stubs(:exists?).with('/var/lib/astute/mongodb/mongodb.key').returns(true)
      File.stubs(:exists?).with('/var/lib/astute/ceph/ceph').returns(true)
      File.stubs(:exists?).with('/var/lib/astute/nova/nova').returns(true)
      File.stubs(:exists?).with('/var/lib/astute/ceph/ceph').returns(true)
      File.stubs(:exists?).returns(false)
      should compile
    }
  end

  shared_examples 'save_files_list' do
    it 'should save the list of file resources' do
      catalog = subject
      catalog = subject.call if subject.is_a? Proc
      file_resources = {}
      catalog.resources.each do |resource|
        next unless resource.type == 'File'
        next unless %w(present file).include? resource[:ensure] or not resource[:ensure]

        if resource[:source]
          content = resource[:source]
        elsif resource[:content]
          content = 'TEMPLATE'
        else
          content = nil
        end
        next unless content
        file_resources[resource[:path]] = content
      end
      if file_resources.any?
        Noop.save_file_resources_list manifest, file_resources
      end
    end
  end

  shared_examples 'save_packages_list' do
    it 'should save the list of file resources' do
      catalog = subject
      catalog = subject.call if subject.is_a? Proc
      package_resources = {}
      catalog.resources.each do |resource|
        next unless resource.type == 'Package'
        next if %w(absent purged).include? resource[:ensure] or not resource[:ensure]
        package_resources[resource[:name]] = resource[:ensure]
      end
      if package_resources.any?
        Noop.save_package_resources_list manifest, package_resources
      end
    end
  end

  #######################################
  # Testing on different operating systems
  # Ubuntu
  context 'on Ubuntu platforms' do
    let(:facts) { Noop.ubuntu_facts }
    it_behaves_like 'should_compile'
    if ENV['NOOP_SAVE_RESOURCES_DIR'] and File.directory?(ENV['NOOP_SAVE_RESOURCES_DIR'])
      it_behaves_like 'save_files_list'
      it_behaves_like 'save_packages_list'
    end
    begin
      it_behaves_like 'puppet catalogue'
    rescue ArgumentError
      true
    end
  end

  # CentOS
  context 'on CentOS platforms' do
    let(:facts) { Noop.ubuntu_facts }
    it_behaves_like 'should_compile'
    if ENV['NOOP_SAVE_RESOURCES_DIR'] and File.directory?(ENV['NOOP_SAVE_RESOURCES_DIR'])
      it_behaves_like 'save_files_list'
      it_behaves_like 'save_packages_list'
    end
    begin
      it_behaves_like 'puppet catalogue'
    rescue ArgumentError
      true
    end
  end
end

