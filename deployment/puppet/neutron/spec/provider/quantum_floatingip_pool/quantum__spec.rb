require 'spec_helper'

describe Puppet::Type.type(:neutron_floatingip_pool).provider(:neutron) do

  let(:resource) { Puppet::Type.type(:neutron_floatingip_pool).new(:name => 'admin', :provider => :neutron) }
  let(:provider) { resource.provider }

  describe "#instances" do
    before(:each) do
      provider.class.stubs(:neutron).with(
        '--os-tenant-name', 'admin', '--os-username', 'admin', '--os-password', 'admin', '--os-auth-url', 'http://10.20.1.2:5000/v2.0/',
        ['floatingip-list', ['--format=csv', '--field=id', '--field=floating_ip_address']]).returns('''
"id","floating_ip_address"
"17029d36-72c3-4ab4-9da2-cdecc689842f","10.20.3.132"
"324355f8-0992-4950-8d16-dea6d670b0fe","10.20.3.137"
"aaebec15-b59b-4e03-9b74-e17b49ffa528","10.20.3.133"
"bce4e408-03e3-421a-80c7-a5c96a835c4e","10.20.3.136"
      ''')
      provider.class.stubs(:neutron).with(
        '--os-tenant-name', 'admin', '--os-username', 'admin', '--os-password', 'admin', '--os-auth-url', 'http://10.20.1.2:5000/v2.0/',
        ['floatingip-show', ['--format', 'shell', '17029d36-72c3-4ab4-9da2-cdecc689842f']]
      ).returns('''
fixed_ip_address=""
floating_ip_address="10.20.3.132"
floating_network_id="47ce6a63-e967-42cc-8710-b6feca522ac7"
id="17029d36-72c3-4ab4-9da2-cdecc689842f"
port_id=""
router_id=""
tenant_id="70e116e152c34eac8966f3eaa7080e89"
      ''')
      provider.class.stubs(:neutron).with(
        '--os-tenant-name', 'admin', '--os-username', 'admin', '--os-password', 'admin', '--os-auth-url', 'http://10.20.1.2:5000/v2.0/',
        ['floatingip-show', ['--format', 'shell', '324355f8-0992-4950-8d16-dea6d670b0fe']]
      ).returns('''
fixed_ip_address=""
floating_ip_address="10.20.3.137"
floating_network_id="47ce6a63-e967-42cc-8710-b6feca522ac7"
id="324355f8-0992-4950-8d16-dea6d670b0fe"
port_id=""
router_id=""
tenant_id="315f150b76874b2bb07b9f03530fafc4"
      ''')
      provider.class.stubs(:neutron).with(
        '--os-tenant-name', 'admin', '--os-username', 'admin', '--os-password', 'admin', '--os-auth-url', 'http://10.20.1.2:5000/v2.0/',
        ['floatingip-show', ['--format', 'shell', 'aaebec15-b59b-4e03-9b74-e17b49ffa528']]
      ).returns('''
fixed_ip_address=""
floating_ip_address="10.20.3.133"
floating_network_id="47ce6a63-e967-42cc-8710-b6feca522ac7"
id="aaebec15-b59b-4e03-9b74-e17b49ffa528"
port_id=""
router_id=""
tenant_id="315f150b76874b2bb07b9f03530fafc4"
      ''')
      provider.class.stubs(:neutron).with(
        '--os-tenant-name', 'admin', '--os-username', 'admin', '--os-password', 'admin', '--os-auth-url', 'http://10.20.1.2:5000/v2.0/',
        ['floatingip-show', ['--format', 'shell', 'bce4e408-03e3-421a-80c7-a5c96a835c4e']]
      ).returns('''
fixed_ip_address=""
floating_ip_address="10.20.3.136"
floating_network_id="47ce6a63-e967-42cc-8710-b6feca522ac7"
id="bce4e408-03e3-421a-80c7-a5c96a835c4e"
port_id=""
router_id=""
tenant_id="315f150b76874b2bb07b9f03530fafc4"
      ''')
      provider.stubs(:keystone).with(
        '--os-tenant-name', "admin", '--os-username', "admin", '--os-password', "admin",
        '--os-auth-url', "http://10.20.1.2:5000/v2.0/", 'tenant-list'
      ).returns('''
+----------------------------------+----------+---------+
|                id                |   name   | enabled |
+----------------------------------+----------+---------+
| 70e116e152c34eac8966f3eaa7080e89 |  admin   |   True  |
| 719179116f3c47129cb2d2a96ed62177 | services |   True  |
| 315f150b76874b2bb07b9f03530fafc4 |   ttt    |   True  |
+----------------------------------+----------+---------+
      ''')

      # provider.class.stubs(:tenants_by_name => {
      #   'admin' => '70e116e152c34eac8966f3eaa7080e89',
      #   'services' => '719179116f3c47129cb2d2a96ed62177',
      #   'ttt' => '315f150b76874b2bb07b9f03530fafc4'
      # })
      # provider.class.stubs(:tenants_by_id =>{
      #   '70e116e152c34eac8966f3eaa7080e89' => 'admin',
      #   '719179116f3c47129cb2d2a96ed62177' => 'services',
      #   '315f150b76874b2bb07b9f03530fafc4' => 'ttt'
      # })

      provider.class.stubs(:neutron_credentials).returns({
        'auth_url'          => "http://10.20.1.2:5000/v2.0/",
        'admin_user'        => "admin",
        'admin_password'    => "admin",
        'admin_tenant_name' => "admin"
      })
      # export OS_TENANT_NAME=admin
      # export OS_USERNAME=admin
      # export OS_PASSWORD=admin
      # export OS_AUTH_URL="http://10.20.1.2:5000/v2.0/"
      # export OS_AUTH_STRATEGY=keystone
      # export SERVICE_TOKEN=jgi14qOR
      # export SERVICE_ENDPOINT=http://10.20.1.2:35357/v2.0/
    end

    it "should find instances" do

#       provider.class.stubs(:floatingip_show).with(['--format', 'shell', '324355f8-0992-4950-8d16-dea6d670b0fe']).returns(
#       '''
#       '''
#       )
      # out=File.open(File.dirname(__FILE__) + '/../../../../fixtures/cib/cib.xml')
      # provider.class.stubs(:dump_cib).returns(out,nil)
      resources = []
      provider.class.instances.each do |instance|
        resources << instance.instance_eval{@property_hash}
      end

      resources[0].should eql(
      {:name=>:bar,:provided_by=>"pacemaker",:ensure=>:present,:parameters=>{},:primitive_class=>"ocf",:primitive_type=>"Dummy",:operations=>{"monitor"=>{"interval"=>"20"}},:metadata=>{},:ms_metadata=>{},:multistate_hash=>{},:provider=>:crm}
      )
    end
  end

  # describe "#create" do

  #   before(:each) do
  #     provider.class.stubs(:exec_withenv).returns(0)
  #   end

  #   it "should create resource with 5 floatings for admin tenant" do
  #     provider.class.stubs(:prefetch)
  #     resource[:tenant] = "admin"
  #     resource[:size] = 5
  #     # tmpfile = StringIO.new()
  #     # Tempfile.stubs(:open).with("puppet_crm_update").yields(tmpfile)
  #     # tmpfile.stubs(:path)
  #     # tmpfile.expects(:write).with("primitive myresource ocf:pacemaker:Dummy op monitor interval=20  ")
  #     provider.class.prefetch({})
  #     provider.create
  #     provider.flush
  #   end

  # end
end
# vim: set ts=2 sw=2 et :