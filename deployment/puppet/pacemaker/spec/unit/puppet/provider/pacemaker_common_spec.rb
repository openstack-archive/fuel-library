require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../lib/puppet/provider/pacemaker_common.rb'))

describe Puppet::Provider::Pacemaker_common do

  cib_xml_file = File.join File.dirname(__FILE__), 'cib.xml'

  let(:raw_cib) do
    File.read cib_xml_file
  end

  let(:resources_regexp) do
    %r{nova|cinder|glance|keystone|neutron|sahara|murano|ceilometer|heat|swift}
  end

  let :location_data do
    {
        "vip__public-on-node-1" =>
            {
                "score" => "100",
                "rsc" => "vip__public",
                "id" => "vip__public-on-node-1",
                "node" => "node-1"
            },
        "loc_ping_vip__public" =>
            {
                "rsc" => "vip__public",
                "id" => "loc_ping_vip__public",
                "rules" => [
                    {
                        "score"=>"-INFINITY",
                        "id"=>"loc_ping_vip__public-rule",
                        "boolean-op"=>"or",
                        "expressions"=> [
                            {
                                "attribute"=>"pingd",
                                "id"=>"loc_ping_vip__public-expression",
                                "operation"=>"not_defined"
                            },
                            {
                             "attribute"=>"pingd",
                             "id"=>"loc_ping_vip__public-expression-0",
                             "operation"=>"lte", "value"=>"0"
                            },
                        ]
                    }
                ],
            },
    }
  end

  let :colocation_data do
    {
        "vip_management-with-haproxy" => {
            'rsc' => "vip__management",
            'score' => "INFINITY",
            'with-rsc' => "clone_p_haproxy",
            'id' => "vip_management-with-haproxy",
        }
    }
  end

  let :order_data do
    {
        'p_neutron-dhcp-agent-after-clone_p_neutron-plugin-openvswitch-agent' => {
            'first' => "clone_p_neutron-plugin-openvswitch-agent",
            'id' => "p_neutron-dhcp-agent-after-clone_p_neutron-plugin-openvswitch-agent",
            'score' => "INFINITY",
            'then' => "p_neutron-dhcp-agent",
        }
    }
  end

  let(:primitive_data) do
    {
        "p_rabbitmq-server" =>
            {"name" => "master_p_rabbitmq-server",
             "class" => "ocf",
             "id" => "p_rabbitmq-server",
             "provider" => "mirantis",
             "type" => "rabbitmq-server",
             "complex" =>
                 {"id" => "master_p_rabbitmq-server",
                  "type" => "master",
                  "meta_attributes" =>
                      {"notify" =>
                           {"id" => "master_p_rabbitmq-server-meta_attributes-notify",
                            "name" => "notify",
                            "value" => "true"},
                       "master-node-max" =>
                           {"id" => "master_p_rabbitmq-server-meta_attributes-master-node-max",
                            "name" => "master-node-max",
                            "value" => "1"},
                       "ordered" =>
                           {"id" => "master_p_rabbitmq-server-meta_attributes-ordered",
                            "name" => "ordered",
                            "value" => "false"},
                       "target-role" =>
                           {"id" => "master_p_rabbitmq-server-meta_attributes-target-role",
                            "name" => "target-role",
                            "value" => "Master"},
                       "master-max" =>
                           {"id" => "master_p_rabbitmq-server-meta_attributes-master-max",
                            "name" => "master-max",
                            "value" => "1"},
                       "interleave" =>
                           {"id" => "master_p_rabbitmq-server-meta_attributes-interleave",
                            "name" => "interleave",
                            "value" => "true"}}},
             "instance_attributes" =>
                 {"node_port" =>
                      {"id" => "p_rabbitmq-server-instance_attributes-node_port",
                       "name" => "node_port",
                       "value" => "5673"}},
             "meta_attributes" =>
                 {"migration-threshold" =>
                      {"id" => "p_rabbitmq-server-meta_attributes-migration-threshold",
                       "name" => "migration-threshold",
                       "value" => "INFINITY"},
                  "failure-timeout" =>
                      {"id" => "p_rabbitmq-server-meta_attributes-failure-timeout",
                       "name" => "failure-timeout",
                       "value" => "60s"}},
             "operations" =>
                 {"p_rabbitmq-server-promote-0" =>
                      {"id" => "p_rabbitmq-server-promote-0",
                       "interval" => "0",
                       "name" => "promote",
                       "timeout" => "120"},
                  "p_rabbitmq-server-monitor-30" =>
                      {"id" => "p_rabbitmq-server-monitor-30",
                       "interval" => "30",
                       "name" => "monitor",
                       "timeout" => "60"},
                  "p_rabbitmq-server-start-0" =>
                      {"id" => "p_rabbitmq-server-start-0",
                       "interval" => "0",
                       "name" => "start",
                       "timeout" => "120"},
                  "p_rabbitmq-server-monitor-27" =>
                      {"id" => "p_rabbitmq-server-monitor-27",
                       "interval" => "27",
                       "name" => "monitor",
                       "role" => "Master",
                       "timeout" => "60"},
                  "p_rabbitmq-server-stop-0" =>
                      {"id" => "p_rabbitmq-server-stop-0",
                       "interval" => "0",
                       "name" => "stop",
                       "timeout" => "60"},
                  "p_rabbitmq-server-notify-0" =>
                      {"id" => "p_rabbitmq-server-notify-0",
                       "interval" => "0",
                       "name" => "notify",
                       "timeout" => "60"},
                  "p_rabbitmq-server-demote-0" =>
                      {"id" => "p_rabbitmq-server-demote-0",
                       "interval" => "0",
                       "name" => "demote",
                       "timeout" => "60"}}},
        "p_neutron-dhcp-agent" =>
            {"name" => "p_neutron-dhcp-agent",
             "class" => "ocf",
             "id" => "p_neutron-dhcp-agent",
             "provider" => "mirantis",
             "type" => "neutron-agent-dhcp",
             "instance_attributes" =>
                 {"os_auth_url" =>
                      {"id" => "p_neutron-dhcp-agent-instance_attributes-os_auth_url",
                       "name" => "os_auth_url",
                       "value" => "http://10.108.2.2:35357/v2.0"},
                  "amqp_server_port" =>
                      {"id" => "p_neutron-dhcp-agent-instance_attributes-amqp_server_port",
                       "name" => "amqp_server_port",
                       "value" => "5673"},
                  "multiple_agents" =>
                      {"id" => "p_neutron-dhcp-agent-instance_attributes-multiple_agents",
                       "name" => "multiple_agents",
                       "value" => "false"},
                  "password" =>
                      {"id" => "p_neutron-dhcp-agent-instance_attributes-password",
                       "name" => "password",
                       "value" => "7BqMhboS"},
                  "tenant" =>
                      {"id" => "p_neutron-dhcp-agent-instance_attributes-tenant",
                       "name" => "tenant",
                       "value" => "services"},
                  "username" =>
                      {"id" => "p_neutron-dhcp-agent-instance_attributes-username",
                       "name" => "username",
                       "value" => "undef"}},
             "meta_attributes" =>
                 {"resource-stickiness" =>
                      {"id" => "p_neutron-dhcp-agent-meta_attributes-resource-stickiness",
                       "name" => "resource-stickiness",
                       "value" => "1"}},
             "operations" =>
                 {"p_neutron-dhcp-agent-monitor-20" =>
                      {"id" => "p_neutron-dhcp-agent-monitor-20",
                       "interval" => "20",
                       "name" => "monitor",
                       "timeout" => "10"},
                  "p_neutron-dhcp-agent-start-0" =>
                      {"id" => "p_neutron-dhcp-agent-start-0",
                       "interval" => "0",
                       "name" => "start",
                       "timeout" => "60"},
                  "p_neutron-dhcp-agent-stop-0" =>
                      {"id" => "p_neutron-dhcp-agent-stop-0",
                       "interval" => "0",
                       "name" => "stop",
                       "timeout" => "60"}}},
    }
  end

  ###########################

  before(:each) do
    @class = subject
    @class.stubs(:raw_cib).returns raw_cib
  end

  context 'configuration' do
    it 'can obtain a CIB XML object' do
      expect(@class.cib.to_s).to include '<configuration>'
      expect(@class.cib.to_s).to include '<nodes>'
      expect(@class.cib.to_s).to include '<resources>'
      expect(@class.cib.to_s).to include '<status>'
      expect(@class.cib.to_s).to include '<operations>'
    end

    it 'can get primitives section of CIB XML' do
      expect(@class.cib_section_primitives).to be_a(Array)
      expect(@class.cib_section_primitives.first.to_s).to start_with '<primitive'
      expect(@class.cib_section_primitives.first.to_s).to end_with '</primitive>'
    end

    it 'can get primitives configuration' do
      expect(@class.primitives).to be_a Hash
      expect(@class.primitives['vip__public']).to be_a Hash
      expect(@class.primitives['vip__public']['meta_attributes']).to be_a Hash
      expect(@class.primitives['vip__public']['instance_attributes']).to be_a Hash
      expect(@class.primitives['vip__public']['instance_attributes']['ip']).to be_a Hash
      expect(@class.primitives['vip__public']['operations']).to be_a Hash
      expect(@class.primitives['vip__public']['meta_attributes']['resource-stickiness']).to be_a Hash
      expect(@class.primitives['vip__public']['operations']['vip__public-start-0']).to be_a Hash
    end

    it 'can determine is primitive is simple or complex' do
      expect(@class.primitive_is_complex? 'p_haproxy').to eq true
      expect(@class.primitive_is_complex? 'vip__management').to eq false
    end
  end

  context 'status' do
    it 'can produce nodes structure' do
      expect(@class.nodes).to be_a Hash
      expect(@class.nodes['node-1']['primitives']['p_heat-engine']['status']).to eq('start')
    end

    it 'can generate a debug output' do
      debug = @class.cluster_debug_report
      expect(debug).to be_a String
      expect(debug).not_to eq ''
    end

    it 'can determine the name of the DC node' do
      expect(@class.dc).to eq 'node-1'
    end

    it 'can determite a global primitive status' do
      expect(@class.primitive_status 'p_heat-engine').to eq('start')
      expect(@class.primitive_is_running? 'p_heat-engine').to eq true
      expect(@class.primitive_status 'p_ceilometer-agent-central').to eq('stop')
      expect(@class.primitive_is_running? 'p_ceilometer-agent-central').to eq false
      expect(@class.primitive_is_running? 'UNKNOWN').to eq nil
      expect(@class.primitive_status 'UNKNOWN').to eq nil
    end

    it 'can determine a local primitive status on a node' do
      expect(@class.primitive_status 'p_heat-engine', 'node-1').to eq('start')
      expect(@class.primitive_is_running? 'p_heat-engine', 'node-1').to eq true
      expect(@class.primitive_status 'p_heat-engine', 'node-2').to eq('stop')
      expect(@class.primitive_is_running? 'p_heat-engine', 'node-2').to eq false
      expect(@class.primitive_is_running? 'UNKNOWN', 'node-1').to eq nil
      expect(@class.primitive_status 'UNKNOWN', 'node-1').to eq nil
    end

    it 'can determine if primitive is managed or not' do
      expect(@class.primitive_is_managed? 'p_heat-engine').to eq true
      expect(@class.primitive_is_managed? 'p_haproxy').to eq true
      expect(@class.primitive_is_managed? 'UNKNOWN').to eq nil
    end

    it 'can determine if primitive is started or not' do
      expect(@class.primitive_is_started? 'p_heat-engine').to eq true
      expect(@class.primitive_is_started? 'p_haproxy').to eq true
      expect(@class.primitive_is_started? 'UNKNOWN').to eq nil
    end

    it 'can determine if primitive is failed or not globally' do
      expect(@class.primitive_has_failures? 'p_ceilometer-agent-central').to eq true
      expect(@class.primitive_has_failures? 'p_heat-engine').to eq false
      expect(@class.primitive_has_failures? 'UNKNOWN').to eq nil
    end

    it 'can determine if primitive is failed or not locally' do
      expect(@class.primitive_has_failures? 'p_ceilometer-agent-central', 'node-1').to eq false
      expect(@class.primitive_has_failures? 'p_ceilometer-agent-central', 'node-2').to eq true
      expect(@class.primitive_has_failures? 'p_heat-engine', 'node-1').to eq false
      expect(@class.primitive_has_failures? 'p_heat-engine', 'node-2').to eq false
      expect(@class.primitive_has_failures? 'UNKNOWN', 'node-1').to eq nil
    end

    it 'can determine that primitive is complex' do
      expect(@class.primitive_is_complex? 'p_haproxy').to eq true
      expect(@class.primitive_is_complex? 'p_heat-engine').to eq false
      expect(@class.primitive_is_complex? 'p_rabbitmq-server').to eq true
      expect(@class.primitive_is_complex? 'UNKNOWN').to eq nil
    end

    it 'can determine that primitive is multistate' do
      expect(@class.primitive_is_multistate? 'p_haproxy').to eq false
      expect(@class.primitive_is_multistate? 'p_heat-engine').to eq false
      expect(@class.primitive_is_multistate? 'p_rabbitmq-server').to eq true
      expect(@class.primitive_is_multistate? 'UNKNOWN').to eq nil
    end

    it 'can determine that primitive has master running' do
      expect(@class.primitive_has_master_running? 'p_rabbitmq-server').to eq true
      expect(@class.primitive_has_master_running? 'p_heat-engine').to eq false
      expect(@class.primitive_has_master_running? 'UNKNOWN').to eq nil
    end

    it 'can determine that primitive is clone' do
      expect(@class.primitive_is_clone? 'p_haproxy').to eq true
      expect(@class.primitive_is_clone? 'p_heat-engine').to eq false
      expect(@class.primitive_is_clone? 'p_rabbitmq-server').to eq false
      expect(@class.primitive_is_clone? 'UNKNOWN').to eq nil
    end
  end

  context 'properties' do
    it 'can get cluster property value' do
      expect(@class.cluster_property_value 'no-quorum-policy').to eq 'ignore'
      expect(@class.cluster_property_value 'UNKNOWN').to be_nil
    end

    it 'can set cluster property value' do
      @class.expects(:crm_attribute).returns true
      @class.cluster_property_set 'no-quorum-policy', 'ignore'
    end

    it 'can delete cluster property value' do
      @class.expects(:crm_attribute).returns true
      @class.cluster_property_delete 'no-quorum-policy'
    end

    it 'can determine if a property is defined' do
      expect(@class.cluster_property_defined? 'no-quorum-policy').to eq(true)
      expect(@class.cluster_property_defined? 'UNKNOWN').to eq(false)
    end
  end

  context 'constraints control' do
    context 'location' do
      it 'can get the location structure from the CIB XML' do
        expect(@class.constraint_locations).to be_a(Hash)
        expect(@class.constraint_locations['p_heat-engine-on-node-1']).to be_a(Hash)
        expect(@class.constraint_locations['p_heat-engine-on-node-1']['rsc']).to be_a String
      end

      let(:location_structure) {
        {
          :id => 'test-on-node1',
          :node => 'node1',
          :rsc => 'test',
          :score => '200',
        }
      }
      let(:location_xml) {
        <<-eof
<diff>
  <diff-added>
    <cib>
      <configuration>
        <constraints>
          <rsc_location __crm_diff_marker__='added:top' id='test-on-node1' node='node1' rsc='test' score='200'/>
        </constraints>
      </configuration>
    </cib>
  </diff-added>
</diff>
        eof
      }
      it 'can add a location constraint' do
        @class.expects(:cibadmin_apply_patch).with(location_xml).returns(true)
        @class.constraint_location_add location_structure
      end

      it 'can check if a location constraint exists' do
        expect(@class.constraint_location_exists? 'p_heat-engine-on-node-1').to eq(true)
        expect(@class.constraint_location_exists? 'UNKNOWN').to eq(false)
      end

      it 'can remove a location constraint' do
        @class.expects(:cibadmin).returns(true)
        @class.constraint_location_remove 'test-on-node1'
      end

      it 'can add a service location constraint' do
        @class.expects(:cibadmin_apply_patch).with(location_xml).returns(true)
        @class.service_location_add 'test', 'node1', '200'
      end

      it 'can check if a service location constraint exists' do
        expect(@class.service_location_exists?('test', 'node1')).to eq(false)
        expect(@class.service_location_exists?('p_heat-engine', 'node-1')).to eq(true)
      end

    end

    context 'colocation' do
      it 'can get the colocation structure from the CIB XML' do
        expect(@class.constraint_colocations).to be_a(Hash)
        expect(@class.constraint_colocations['vip_management-with-haproxy']).to be_a(Hash)
        expect(@class.constraint_colocations['vip_management-with-haproxy']['with-rsc']).to be_a String
      end
    end

    context 'order' do
      it 'can get the order structure from the CIB XML' do
        expect(@class.constraint_orders).to be_a(Hash)
        name = 'p_neutron-dhcp-agent-after-clone_p_neutron-plugin-openvswitch-agent'
        expect(@class.constraint_orders[name]).to be_a(Hash)
        expect(@class.constraint_orders[name]['first']).to be_a String
      end
    end
  end

  context 'retry_functions' do
    it 'retries block until it becomes true' do
      @class.retry_block { true }
    end

    it 'waits for Pacemaker to become ready' do
      @class.stubs(:is_online?).returns true
      @class.wait_for_online
    end

    it 'waits for a primitive to have a known status' do
      @class.stubs(:cib_reset).returns true
      @class.stubs(:primitive_status).returns 'stopped'
      @class.wait_for_status 'myprimitive', 'mynode'
    end

    it 'waits for the service to start' do
      @class.stubs(:cib_reset).returns true
      @class.stubs(:primitive_is_running?).with('myprimitive', nil).returns true
      @class.wait_for_start 'myprimitive'
    end

    it 'waits for the service to stop' do
      @class.stubs(:cib_reset).returns true
      @class.stubs(:primitive_is_running?).with('myprimitive', nil).returns false
      @class.wait_for_stop 'myprimitive'
    end
  end

  context 'xml_generation' do

    it 'can create a new XML document with the specified path' do
      doc = @class.xml_document %w(a b c)
      expect(doc).to be_a(REXML::Element)
      expect(doc.to_s).to eq('<c/>')
      expect(doc.root.to_s).to eq('<a><b><c/></b></a>')
    end

    it 'can format an xml element' do
      element = REXML::Element.new 'test'
      element.add_attribute 'a', 1
      element.add_attribute 'b', 2
      child = element.add_element 'c'
      child.add_attribute 'd', 3
      xml = <<-eos
<test a='1' b='2'>
  <c d='3'/>
</test>
      eos
      expect(@class.xml_pretty_format element).to eq(xml)
    end

    it 'can create a new element using the existing document' do
      doc = REXML::Document.new
      doc = doc.add_element 'a'
      element = @class.xml_document 'b', doc
      expect(element).to be_a(REXML::Element)
      expect(element.to_s).to eq('<b/>')
      expect(element.root.to_s).to eq('<a><b/></a>')
    end

    it 'can create a new xml element from a hash' do
      hash = {'a' => '1', 'b' => 2, 'c' => :d, :e => [1, 2, 3], :f => {:g => 1, :h => 2}, 'o' => 'skip'}
      element = @class.xml_element 'test', hash, 'o'
      expect(element.to_s).to eq("<test a='1' b='2' c='d'/>")
    end

    it 'can create an xml element from a simple rsc_location data structure' do
      data = location_data['vip__public-on-node-1']
      location = @class.xml_rsc_location data
      expect(@class.xml_pretty_format location).to eq(<<-eos
<rsc_location id='vip__public-on-node-1' node='node-1' rsc='vip__public' score='100'/>
                                                   eos
                                                   )
    end

    context 'location' do
      it 'can create an xml element from a rule based rsc_location structure' do
        data = location_data['loc_ping_vip__public']
        location = @class.xml_rsc_location data
        expect(@class.xml_pretty_format location).to eq(<<-eos
<rsc_location id='loc_ping_vip__public' rsc='vip__public'>
  <rule boolean-op='or' id='loc_ping_vip__public-rule' score='-INFINITY'>
    <expression attribute='pingd' id='loc_ping_vip__public-expression' operation='not_defined'/>
    <expression attribute='pingd' id='loc_ping_vip__public-expression-0' operation='lte' value='0'/>
  </rule>
</rsc_location>
                                                     eos
                                                     )
      end

      it 'can match a generated and a parsed XML to the original data for a rule based location' do
        original_data = location_data['loc_ping_vip__public']
        require 'pp'
        generated_location_element = @class.xml_rsc_location original_data
        decoded_data = @class.decode_constraint generated_location_element
        decoded_data.delete 'type'
        expect(original_data).to eq(decoded_data)
      end

      it 'can match a generated and a parsed XML to the original data for a simple location' do
        original_data = location_data['vip__public-on-node-1']
        generated_location_element = @class.xml_rsc_location original_data
        decoded_data = @class.decode_constraint generated_location_element
        decoded_data.delete 'type'
        expect(original_data).to eq(decoded_data)
      end
    end

    context 'colocation' do
      it 'can create an XML element from a rsc_colocation structure' do
        data = colocation_data['vip_management-with-haproxy']
        colocation = @class.xml_rsc_colocation data
        expect(@class.xml_pretty_format colocation).to eq(<<-eos
<rsc_colocation id='vip_management-with-haproxy' rsc='vip__management' score='INFINITY' with-rsc='clone_p_haproxy'/>
                                                       eos
                                                       )
      end

      it 'can match a generated and a parsed XML to the original data for a colocation' do
        original_data = colocation_data['vip_management-with-haproxy']
        generated_colocation_element = @class.xml_rsc_colocation original_data
        decoded_data = @class.decode_constraint generated_colocation_element
        decoded_data.delete 'type'
        expect(original_data).to eq(decoded_data)
      end
    end

    context 'order' do
      it 'can create an XML element from a rsc_order structure' do
        data = order_data['p_neutron-dhcp-agent-after-clone_p_neutron-plugin-openvswitch-agent']
        order = @class.xml_rsc_order data
        expect(@class.xml_pretty_format order).to eq(<<-eos
<rsc_order first='clone_p_neutron-plugin-openvswitch-agent' id='p_neutron-dhcp-agent-after-clone_p_neutron-plugin-openvswitch-agent' score='INFINITY' then='p_neutron-dhcp-agent'/>
                                                  eos
                                                  )
      end

      it 'can match a generated and a parsed XML to the original data for an order' do
        original_data = order_data['p_neutron-dhcp-agent-after-clone_p_neutron-plugin-openvswitch-agent']
        generated_order_element = @class.xml_rsc_colocation original_data
        decoded_data = @class.decode_constraint generated_order_element
        decoded_data.delete 'type'
        expect(original_data).to eq(decoded_data)
      end
    end

    context 'primitive' do
      it 'can create an XML element from a simple primitive structure' do
        data = primitive_data['p_neutron-dhcp-agent']
        primitive_element = @class.xml_primitive data
        expect(@class.xml_pretty_format primitive_element).to eq(<<-eos
<primitive class='ocf' id='p_neutron-dhcp-agent' provider='mirantis' type='neutron-agent-dhcp'>
  <instance_attributes id='p_neutron-dhcp-agent-instance_attributes'>
    <nvpair id='p_neutron-dhcp-agent-instance_attributes-amqp_server_port' name='amqp_server_port' value='5673'/>
    <nvpair id='p_neutron-dhcp-agent-instance_attributes-multiple_agents' name='multiple_agents' value='false'/>
    <nvpair id='p_neutron-dhcp-agent-instance_attributes-os_auth_url' name='os_auth_url' value='http://10.108.2.2:35357/v2.0'/>
    <nvpair id='p_neutron-dhcp-agent-instance_attributes-password' name='password' value='7BqMhboS'/>
    <nvpair id='p_neutron-dhcp-agent-instance_attributes-tenant' name='tenant' value='services'/>
    <nvpair id='p_neutron-dhcp-agent-instance_attributes-username' name='username' value='undef'/>
  </instance_attributes>
  <meta_attributes id='p_neutron-dhcp-agent-meta_attributes'>
    <nvpair id='p_neutron-dhcp-agent-meta_attributes-resource-stickiness' name='resource-stickiness' value='1'/>
  </meta_attributes>
  <operations>
    <op id='p_neutron-dhcp-agent-monitor-20' interval='20' name='monitor' timeout='10'/>
    <op id='p_neutron-dhcp-agent-start-0' interval='0' name='start' timeout='60'/>
    <op id='p_neutron-dhcp-agent-stop-0' interval='0' name='stop' timeout='60'/>
  </operations>
</primitive>
                                                              eos
                                                              )
      end

      it 'can create an XML element from a complex primitive structure' do
        data = primitive_data['p_rabbitmq-server']
        primitive_element = @class.xml_primitive data
        expect(@class.xml_pretty_format primitive_element).to eq(<<-eos
<master id='master_p_rabbitmq-server'>
  <meta_attributes id='master_p_rabbitmq-server-meta_attributes'>
    <nvpair id='master_p_rabbitmq-server-meta_attributes-interleave' name='interleave' value='true'/>
    <nvpair id='master_p_rabbitmq-server-meta_attributes-master-max' name='master-max' value='1'/>
    <nvpair id='master_p_rabbitmq-server-meta_attributes-master-node-max' name='master-node-max' value='1'/>
    <nvpair id='master_p_rabbitmq-server-meta_attributes-notify' name='notify' value='true'/>
    <nvpair id='master_p_rabbitmq-server-meta_attributes-ordered' name='ordered' value='false'/>
    <nvpair id='master_p_rabbitmq-server-meta_attributes-target-role' name='target-role' value='Master'/>
  </meta_attributes>
  <primitive class='ocf' id='p_rabbitmq-server' provider='mirantis' type='rabbitmq-server'>
    <instance_attributes id='p_rabbitmq-server-instance_attributes'>
      <nvpair id='p_rabbitmq-server-instance_attributes-node_port' name='node_port' value='5673'/>
    </instance_attributes>
    <meta_attributes id='p_rabbitmq-server-meta_attributes'>
      <nvpair id='p_rabbitmq-server-meta_attributes-failure-timeout' name='failure-timeout' value='60s'/>
      <nvpair id='p_rabbitmq-server-meta_attributes-migration-threshold' name='migration-threshold' value='INFINITY'/>
    </meta_attributes>
    <operations>
      <op id='p_rabbitmq-server-demote-0' interval='0' name='demote' timeout='60'/>
      <op id='p_rabbitmq-server-monitor-27' interval='27' name='monitor' role='Master' timeout='60'/>
      <op id='p_rabbitmq-server-monitor-30' interval='30' name='monitor' timeout='60'/>
      <op id='p_rabbitmq-server-notify-0' interval='0' name='notify' timeout='60'/>
      <op id='p_rabbitmq-server-promote-0' interval='0' name='promote' timeout='120'/>
      <op id='p_rabbitmq-server-start-0' interval='0' name='start' timeout='120'/>
      <op id='p_rabbitmq-server-stop-0' interval='0' name='stop' timeout='60'/>
    </operations>
  </primitive>
</master>
                                                              eos
                                                              )
      end

      it 'can match a generated and a parsed XML to the original data for a simple primitive' do
        original_data = primitive_data['p_neutron-dhcp-agent']
        generated_primitive_element = @class.xml_primitive original_data
        @class.stubs(:raw_cib).returns @class.xml_pretty_format(generated_primitive_element)
        parsed_data = @class.primitives['p_neutron-dhcp-agent']
        expect(parsed_data).to eq original_data
      end

      it 'can match a generated and a parsed XML to the original data for a complex primitive' do
        original_data = primitive_data['p_rabbitmq-server']
        generated_primitive_element = @class.xml_primitive original_data
        @class.stubs(:raw_cib).returns @class.xml_pretty_format(generated_primitive_element)
        parsed_data = @class.primitives['p_rabbitmq-server']
        expect(parsed_data).to eq original_data
      end
    end

  end

end
