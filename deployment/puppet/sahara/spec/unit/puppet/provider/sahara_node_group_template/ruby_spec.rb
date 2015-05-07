require 'puppet'
require 'ostruct'

describe Puppet::Type.type(:sahara_node_group_template).provider(:ruby) do
  let(:properties) do
    {
      :ensure => 'present',
      :name => 'hdp-2-master',
      :plugin_name => 'hdp',
      :flavor_id => 'm1.large',
      :node_processes => ["NAMENODE", "SECONDARY_NAMENODE", "ZOOKEEPER_SERVER", "ZOOKEEPER_CLIENT", "HISTORYSERVER", "RESOURCEMANAGER", "OOZIE_SERVER"],
      :hadoop_version => '2.0.6',
      :auth_password => 'password',
    }
  end

  let(:resource) do
    Puppet::Type.type(:sahara_node_group_template).new properties
  end

  let(:provider) do
    provider = resource.provider
    if ENV['SPEC_PUPPET_DEBUG']
      class << provider
        def debug(msg)
          puts msg
        end
      end
    end
    provider
  end

  let(:node_group_template_list) do
    [
    OpenStruct.new(
      :node_processes => ["NAMENODE", "SECONDARY_NAMENODE", "ZOOKEEPER_SERVER", "ZOOKEEPER_CLIENT", "HISTORYSERVER", "RESOURCEMANAGER", "OOZIE_SERVER"],
      :hadoop_version => "2.0.6",
      :floating_ip_pool => "6c8a9193-7d2e-4465-b564-1feb82220f14",
      :auto_security_group => true,
      :plugin_name => "hdp",
      :description => "The master node contains all management Hadoop components like NameNode, HistoryServer and ResourceManager. It also includes Oozie server required to run Hadoop jobs.",
      :name => "hdp-2-master",
      :flavor_id => "4",
      :id=>"38f7c7f3-e29d-4e49-8c69-b655fba5095b",
    )
    ]
  end

  let(:list_flavors) do
    [
      OpenStruct.new(:id => '3', :name => 'm1.medium'),
      OpenStruct.new(:id => '4', :name => 'm1.large'),
    ]
  end

  let(:list_routers) do
    [
      OpenStruct.new(:name => 'router04', :external_gateway_info => {'network_id' => "6c8a9193-7d2e-4465-b564-1feb82220f14" })
    ]
  end

  let(:extracted_property_hash) do
    {
      :ensure=>:present,
      :id=>"38f7c7f3-e29d-4e49-8c69-b655fba5095b",
      :name=>"hdp-2-master",
      :description=>"The master node contains all management Hadoop components like NameNode, HistoryServer and ResourceManager. It also includes Oozie server required to run Hadoop jobs.",
      :plugin_name=>"hdp",
      :flavor_id=>"4",
      :hadoop_version => "2.0.6",
      :node_processes=>["NAMENODE", "SECONDARY_NAMENODE", "ZOOKEEPER_SERVER", "ZOOKEEPER_CLIENT", "HISTORYSERVER", "RESOURCEMANAGER", "OOZIE_SERVER"], :hadoop_version=>"2.0.6",
      :floating_ip_pool=>"6c8a9193-7d2e-4465-b564-1feb82220f14",
      :auto_security_group=>true,
    }
  end

  let(:new_property_hash) do
    {
      :ensure=>:present,
      :name => "hdp-2-master",
      :description=>"hdp-2-master",
      :plugin_name=>"hdp",
      :flavor_id=>"m1.large",
      :node_processes=>["NAMENODE", "SECONDARY_NAMENODE", "ZOOKEEPER_SERVER", "ZOOKEEPER_CLIENT", "HISTORYSERVER", "RESOURCEMANAGER", "OOZIE_SERVER"],
      :hadoop_version=>"2.0.6",
      :floating_ip_pool=>nil,
      :auto_security_group=>true,
    }
  end

  let(:connection) do
    double 'Connection', {
      :list_node_group_templates => node_group_template_list,
      :create_node_group_template => true,
      :delete_node_group_template => true,
    }
  end

  let(:network_connection) do
    double 'NetworkConnection', {
      :list_routers => list_routers,
    }
  end

  let(:compute_connection) do
    double 'ComputeConnection', {
      :list_flavors => list_flavors,
    }
  end

  before(:each) do
    allow(provider).to receive(:connection).and_return(connection)
    allow(provider).to receive(:network_connection).and_return(network_connection)
    allow(provider).to receive(:compute_connection).and_return(compute_connection)
  end

  context '#exists?' do
    it 'can get the existing node group templates' do
      expect(provider.extract).to eq extracted_property_hash
    end

    it 'can check if the node_group_template exists' do
      provider.extract
      expect(provider.exists?).to eq true
      resource[:name] = 'MISSING'
      provider.extract
      expect(provider.exists?).to eq false
    end

    it 'can get floating_ip_pool from Neutron' do
      provider.exists?
      expect(resource[:floating_ip_pool]).to eq "6c8a9193-7d2e-4465-b564-1feb82220f14"
    end

    it 'uses "nova" for floating_ip_pool if Nova-Network' do
      resource[:neutron] = false
      provider.exists?
      expect(resource[:floating_ip_pool]).to eq 'nova'
    end

    it 'can resolve Flavor name to id' do
      provider.exists?
      expect(resource[:flavor_id]).to eq '4'
    end
  end

  context '#create' do
    it 'creates a new node_group_template' do
      provider.create
      expect(provider.property_hash).to eq new_property_hash
    end
  end

  context '#destroy' do
    it 'can remove the node_group_template by its id' do
      expect(connection).to receive(:delete_node_group_template).with("38f7c7f3-e29d-4e49-8c69-b655fba5095b").and_return(true)
      provider.exists?
      provider.destroy
    end
  end

  context '#flush' do
    it 'creates a new node_group_template' do
      provider.create
      options = new_property_hash.reject { |k, v| [:id, :ensure].include? k }
      expect(connection).to receive(:create_node_group_template).with(options).and_return(true)
      provider.flush
    end

    it 'removes the existing node_group template to update it' do
      provider.exists?
      expect(provider).to receive(:destroy).and_return(true)
      provider.flush
    end

    it 'does nothing if ensure is absent' do
      resource[:ensure] = 'absent'
      provider.exists?
      expect(provider).to receive(:destroy).never
      expect(connection).to receive(:create_node_group_template).never
      provider.flush
    end
  end
end
