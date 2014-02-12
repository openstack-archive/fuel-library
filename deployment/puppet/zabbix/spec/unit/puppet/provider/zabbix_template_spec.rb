
describe "zabbix_template" do
  let(:provider) { Puppet::Type.type(:zabbix_template) }
  
  it "should get defined as provider" do
  
    resource = Puppet::Type.type(:zabbix_template).new({
      :name => 'blerghli',
    })
    resource.provider.class.to_s.should == "Puppet::Type::Zabbix_template::ProviderRuby"
  end
  
  it "should return false on inexistant templates" do
    resource = Puppet::Type.type(:zabbix_template).new({
      :name => 'not rspec zabbix_template',
    })
    Puppet.settings[:config]= "#{File.dirname(__FILE__)}/../../../../tests/etc/puppet.conf"
    resource.provider().exists?().should be_false
  end
  
  it "should return true on existing templates" do
    resource = Puppet::Type.type(:zabbix_template).new({
      :name => 'rspec zabbix_template that exists',
    })
    Puppet.settings[:config]= "#{File.dirname(__FILE__)}/../../../../tests/etc/puppet.conf"
    if !resource.provider().exists?()
      resource.provider().create()
    end
    resource.provider().exists?().should be_true
  end
  
  it "should create a template, find it and delete it again", :broken => true do
    resource = Puppet::Type.type(:zabbix_template).new({
      :name => 'rspec zabbix_template',
    })
    Puppet.settings[:config]= "#{File.dirname(__FILE__)}/../../../../tests/etc/puppet.conf"
    resource.provider().create()
    resource.provider().exists?().should be_true
    resource.provider().destroy()
    resource.provider().exists?().should be_false
  end
end