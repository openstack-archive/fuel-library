
describe "zabbix_hostgroup" do
  let(:provider) { Puppet::Type.type(:zabbix_hostgroup) }
  
  it "should get defined as provider" do
    resource = Puppet::Type.type(:zabbix_hostgroup).new({
      :name => 'inexistant rspec hostgroup',
    })
    resource.provider.class.to_s.should == "Puppet::Type::Zabbix_hostgroup::ProviderRuby"
  end
  
  it "should return false on inexistant hostgroup" do
    resource = Puppet::Type.type(:zabbix_hostgroup).new({
      :name => 'inexistant rspec hostgroup',
    })
    Puppet.settings[:config]= "#{File.dirname(__FILE__)}/../../../../tests/etc/puppet.conf"
    resource.provider().exists?().should be_false
  end
  
  it "should return true on existing hostgroup" do
    resource = Puppet::Type.type(:zabbix_hostgroup).new({
      :name => 'existant rspec hostgroup',
    })
    Puppet.settings[:config]= "#{File.dirname(__FILE__)}/../../../../tests/etc/puppet.conf"
    if !resource.provider().exists?()
      resource.provider().create()
    end
    resource.provider().exists?().should be_true
  end
  
  it "should create a hostgroup, find it and delete it again" do
    resource = Puppet::Type.type(:zabbix_hostgroup).new({
      :name => 'rspec zabbix_hostgroup',
    })
    Puppet.settings[:config]= "#{File.dirname(__FILE__)}/../../../../tests/etc/puppet.conf"
    resource.provider().create()
    resource.provider().exists?().should be_true
    resource.provider().destroy()
    resource.provider().exists?().should be_false
  end
end