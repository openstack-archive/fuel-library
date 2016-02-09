require 'puppet'
require 'ostruct'

describe Puppet::Type.type(:sahara_cluster_template).provider(:ruby) do
  let(:properties) do
    {
      :ensure => 'present',
      :name => 'hdp-2',
      :plugin_name => 'hdp',
      :node_groups => [
         {'name' => 'hdp-2-master', 'count' => 1},
      ],
      :hadoop_version => '2.0.6',
      :auth_password => 'password',
    }
  end

  let(:resource) do
    Puppet::Type.type(:sahara_cluster_template).new properties
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

  let (:groups_property) do
    resource.property(:node_groups)
  end

  let (:is_groups) do
    [{"volume_local_to_instance"=>false, "availability_zone"=>nil,"updated_at"=>nil, "node_group_template_id"=>"d79d30d8-fac3-42c4-b8ff-f4c4d2269563",
      "volumes_per_node"=>0, "id"=>"218b2274-efbf-4c1c-a8cf-58727ec4697a", "security_groups"=>nil, "shares"=>nil, "node_configs"=>{}, "auto_security_group"=>true,
      "volumes_availability_zone"=>nil, "volume_mount_prefix"=>"/volumes/disk", "floating_ip_pool"=>"4dd3f47d-c85a-4649-b679-35ba2904fd0f", "image_id"=>nil,
      "volumes_size"=>0, "is_proxy_gateway"=>false, "count"=>1, "name"=>"hdp-2-master", "created_at"=>"2016-02-07T21:47:29", "volume_type"=>nil,
      "node_processes"=>["namenode", "resourcemanager", "oozie", "historyserver"], "flavor_id"=>"3", "use_autoconfig"=>true}]
  end

  let(:cluster_templates_list) do
    [
    OpenStruct.new(
      :node_groups => [
         {'name' => 'hdp-2-master', 'node_group_template_id' => 'd79d30d8-fac3-42c4-b8ff-f4c4d2269563', 'count' => 1},
      ],
      :hadoop_version => "2.0.6",
      :plugin_name => "hdp",
      :description => "Hortonworks Data Platform (HDP) 2.0.6 cluster with manager, master and 3 worker nodes. The manager node is dedicated to Ambari 1.4.1 management console. The master node contains all management Hadoop processes. Workers contain Hadoop processes for data storage and processing.",
      :name => "hdp-2",
      :id => "fef24e2e-deaa-4b1b-b123-83d02cc5b28e",
      :neutron_management_network => "89980ffb-fac3-4b1b-8416-b655fba5095b",
    )
    ]
  end

  let(:node_group_templates_list) do
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
      :id=>"d79d30d8-fac3-42c4-b8ff-f4c4d2269563",
    )
    ]
  end

  let(:list_networks) do
    [
      OpenStruct.new(:id => '89980ffb-fac3-4b1b-8416-b655fba5095b', :name => 'admin_internal_net'),
    ]
  end

  let(:extracted_property_hash) do
    {
      :ensure=>:present,
      :node_groups => [
         {'name' => 'hdp-2-master', 'node_group_template_id' => 'd79d30d8-fac3-42c4-b8ff-f4c4d2269563', 'count' => 1},
      ],
      :hadoop_version => "2.0.6",
      :plugin_name => "hdp",
      :description => "Hortonworks Data Platform (HDP) 2.0.6 cluster with manager, master and 3 worker nodes. The manager node is dedicated to Ambari 1.4.1 management console. The master node contains all management Hadoop processes. Workers contain Hadoop processes for data storage and processing.",
      :name => "hdp-2",
      :id => "fef24e2e-deaa-4b1b-b123-83d02cc5b28e",
      :neutron_management_network => "89980ffb-fac3-4b1b-8416-b655fba5095b",
    }
  end

  let(:new_property_hash) do
    {
      :ensure=>:present,
      :node_groups => [
         {'name' => 'hdp-2-master', 'count' => 1},
      ],
      :hadoop_version => "2.0.6",
      :plugin_name => "hdp",
      :description => "hdp-2",
      :name => "hdp-2",
      :neutron_management_network => "admin_internal_net",
    }
  end

  let(:connection) do
    double 'Connection', {
      :list_node_group_templates => node_group_templates_list,
      :list_cluster_templates => cluster_templates_list,
      :create_cluster_template => true,
      :delete_cluster_template => true,
    }
  end

  let(:network_connection) do
    double 'NetworkConnection', {
      :list_networks => list_networks,
    }
  end

  before(:each) do
    allow(provider).to receive(:connection).and_return(connection)
    allow(provider).to receive(:network_connection).and_return(network_connection)
  end

  context '#exists?' do
    it 'can get the existing cluster templates' do
      expect(provider.extract).to eq extracted_property_hash
    end

    it 'node_groups are in sync' do
      expect(groups_property.insync?(is_groups)).to be_truthy
    end

    it 'can check if the cluster_template exists' do
      provider.extract
      expect(provider.exists?).to eq true
      resource[:name] = 'MISSING'
      provider.extract
      expect(provider.exists?).to eq false
    end

    it 'can get management_network from Neutron' do
      provider.exists?
      expect(resource[:neutron_management_network]).to eq "89980ffb-fac3-4b1b-8416-b655fba5095b"
    end

    it 'returns nothing for management_network if Nova-Network' do
      resource[:neutron] = false
      provider.exists?
      expect(resource[:neutron_management_network]).to eq 'admin_internal_net'
    end

    it 'can set node group id fro node_groups' do
      provider.exists?
      expect(resource[:node_groups]).to eq [
         {'name' => 'hdp-2-master', 'node_group_template_id' => 'd79d30d8-fac3-42c4-b8ff-f4c4d2269563', 'count' => 1},
      ]
    end
  end

  context '#create' do
    it 'creates a new cluster_template' do
      provider.create
      expect(provider.property_hash).to eq new_property_hash
    end
  end

  context '#destroy' do
    it 'can remove the cluster_template by its id' do
      expect(connection).to receive(:delete_cluster_template).with("fef24e2e-deaa-4b1b-b123-83d02cc5b28e").and_return(true)
      provider.exists?
      provider.destroy
    end
  end

  context '#flush' do
    it 'creates a new cluster_template' do
      provider.create
      options = new_property_hash.reject { |k, v| [:id, :ensure].include? k }
      expect(connection).to receive(:create_cluster_template).with(options).and_return(true)
      provider.flush
    end

    it 'removes the existing cluster template to update it' do
      provider.exists?
      expect(provider).to receive(:destroy).and_return(true)
      provider.flush
    end

    it 'does nothing if ensure is absent' do
      resource[:ensure] = 'absent'
      provider.exists?
      expect(provider).to receive(:destroy).never
      expect(connection).to receive(:create_cluster_template).never
      provider.flush
    end
  end

end
