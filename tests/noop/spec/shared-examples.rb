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
    it { should compile }
  end

  shared_examples 'save_files_list' do
    it 'should save the list of file resources' do
      catalog = subject
      catalog = subject.call if subject.is_a? Proc
      file_resources = {}
      catalog.resources.each do |resource|
        next unless resource.type == 'File'
        next unless resource[:ensure] == 'present' or
                      resource[:ensure] == 'file' or
                        not resource[:ensure]
        file = {}
        file['template'] = !!resource[:content]
        file['source'] = resource[:source] if resource[:source]
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

  #######################################
  # Testing on different operating systems
  # Ubuntu
  context 'on Ubuntu platforms' do
    let(:facts) { Noop.ubuntu_facts }
    it_behaves_like 'should_compile'
    it_behaves_like 'save_files_list'
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
    it_behaves_like 'save_files_list'
    begin
      it_behaves_like 'puppet catalogue'
    rescue ArgumentError
      true
    end
  end
end

