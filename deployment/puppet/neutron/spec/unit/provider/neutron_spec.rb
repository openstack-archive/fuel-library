require 'puppet'
require 'spec_helper'
require 'puppet/provider/neutron'
require 'tempfile'

describe Puppet::Provider::Neutron do

  def klass
    described_class
  end

  let :credential_hash do
    {
      'auth_host'         => '192.168.56.210',
      'auth_port'         => '35357',
      'auth_protocol'     => 'https',
      'admin_tenant_name' => 'admin_tenant',
      'admin_user'        => 'admin',
      'admin_password'    => 'password',
    }
  end

  let :auth_endpoint do
    'https://192.168.56.210:35357/v2.0/'
  end

  let :credential_error do
    /Neutron types will not work/
  end

  after :each do
    klass.reset
  end

  describe 'when determining credentials' do

    it 'should fail if config is empty' do
      conf = {}
      klass.expects(:neutron_conf).returns(conf)
      expect do
        klass.neutron_credentials
      end.to raise_error(Puppet::Error, credential_error)
    end

    it 'should fail if config does not have keystone_authtoken section.' do
      conf = {'foo' => 'bar'}
      klass.expects(:neutron_conf).returns(conf)
      expect do
        klass.neutron_credentials
      end.to raise_error(Puppet::Error, credential_error)
    end

    it 'should fail if config does not contain all auth params' do
      conf = {'keystone_authtoken' => {'invalid_value' => 'foo'}}
      klass.expects(:neutron_conf).returns(conf)
      expect do
       klass.neutron_credentials
      end.to raise_error(Puppet::Error, credential_error)
    end

    it 'should use specified host/port/protocol in the auth endpoint' do
      conf = {'keystone_authtoken' => credential_hash}
      klass.expects(:neutron_conf).returns(conf)
      klass.get_auth_endpoint.should == auth_endpoint
    end

  end

  describe 'when invoking the neutron cli' do

    it 'should set auth credentials in the environment' do
      authenv = {
        :OS_AUTH_URL    => auth_endpoint,
        :OS_USERNAME    => credential_hash['admin_user'],
        :OS_TENANT_NAME => credential_hash['admin_tenant_name'],
        :OS_PASSWORD    => credential_hash['admin_password'],
      }
      klass.expects(:get_neutron_credentials).with().returns(credential_hash)
      klass.expects(:withenv).with(authenv)
      klass.auth_neutron('test_retries')
    end

    ['[Errno 111] Connection refused',
     '(HTTP 400)'].reverse.each do |valid_message|
      it "should retry when neutron cli returns with error #{valid_message}" do
        klass.expects(:get_neutron_credentials).with().returns({})
        klass.expects(:sleep).with(10).returns(nil)
        klass.expects(:neutron).twice.with(['test_retries']).raises(
          Exception, valid_message).then.returns('')
        klass.auth_neutron('test_retries')
      end
    end

  end

  describe 'when listing neutron resources' do

    it 'should exclude the column header' do
      output = <<-EOT
        id
        net1
        net2
      EOT
      klass.expects(:auth_neutron).returns(output)
      result = klass.list_neutron_resources('foo')
      result.should eql(['net1', 'net2'])
    end

  end

  describe 'when retrieving attributes for neutron resources' do

    it 'should parse single-valued attributes into a key-value pair' do
      klass.expects(:auth_neutron).returns('admin_state_up="True"')
      result = klass.get_neutron_resource_attrs('foo', 'id')
      result.should eql({"admin_state_up" => 'True'})
    end

    it 'should parse multi-valued attributes into a key-list pair' do
      output = <<-EOT
subnets="subnet1
subnet2
subnet3"
      EOT
      klass.expects(:auth_neutron).returns(output)
      result = klass.get_neutron_resource_attrs('foo', 'id')
      result.should eql({"subnets" => ['subnet1', 'subnet2', 'subnet3']})
    end

  end

  describe 'when listing router ports' do

    let :router do
      'router1'
    end

    it 'should handle an empty port list' do
      klass.expects(:auth_neutron).with('router-port-list',
                                        '--format=csv',
                                        router)
      result = klass.list_router_ports(router)
      result.should eql([])
    end

    it 'should handle several ports' do
      output = <<-EOT
"id","name","mac_address","fixed_ips"
"1345e576-a21f-4c2e-b24a-b245639852ab","","fa:16:3e:e3:e6:38","{""subnet_id"": ""839a1d2d-2c6e-44fb-9a2b-9b011dce8c2f"", ""ip_address"": ""10.0.0.1""}"
"de0dc526-02b2-467c-9832-2c3dc69ac2b4","","fa:16:3e:f6:b5:72","{""subnet_id"": ""e4db0abd-276a-4f69-92ea-8b9e4eacfd43"", ""ip_address"": ""172.24.4.226""}"
      EOT
      expected =
       [{ "fixed_ips"=>
          "{\"subnet_id\": \"839a1d2d-2c6e-44fb-9a2b-9b011dce8c2f\", \
\"ip_address\": \"10.0.0.1\"}",
          "name"=>"",
          "subnet_id"=>"839a1d2d-2c6e-44fb-9a2b-9b011dce8c2f",
          "id"=>"1345e576-a21f-4c2e-b24a-b245639852ab",
          "mac_address"=>"fa:16:3e:e3:e6:38"},
        {"fixed_ips"=>
          "{\"subnet_id\": \"e4db0abd-276a-4f69-92ea-8b9e4eacfd43\", \
\"ip_address\": \"172.24.4.226\"}",
          "name"=>"",
          "subnet_id"=>"e4db0abd-276a-4f69-92ea-8b9e4eacfd43",
          "id"=>"de0dc526-02b2-467c-9832-2c3dc69ac2b4",
          "mac_address"=>"fa:16:3e:f6:b5:72"}]
      klass.expects(:auth_neutron).
        with('router-port-list', '--format=csv', router).
        returns(output)
      result = klass.list_router_ports(router)
      result.should eql(expected)
    end

  end

  describe 'when parsing creation output' do

    it 'should parse valid output into a hash' do
      data = <<-EOT
Created a new network:
admin_state_up="True"
id="5f9cbed2-d31c-4e9c-be92-87229acb3f69"
name="foo"
tenant_id="3056a91768d948d399f1d79051a7f221"
      EOT
      expected = {
        'admin_state_up' => 'True',
        'id'             => '5f9cbed2-d31c-4e9c-be92-87229acb3f69',
        'name'           => 'foo',
        'tenant_id'      => '3056a91768d948d399f1d79051a7f221',
      }
      klass.parse_creation_output(data).should == expected
    end

  end

end
