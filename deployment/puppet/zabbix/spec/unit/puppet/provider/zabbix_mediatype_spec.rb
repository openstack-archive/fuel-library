
describe "zabbix_mediatype" do
  let(:provider) { Puppet::Type.type(:zabbix_mediatype) }
  
  it "should get defined as provider" do
  
    resource = Puppet::Type.type(:zabbix_mediatype).new({
      :name => 'my rspec mediatype',
    })
    resource.provider.class.to_s.should == "Puppet::Type::Zabbix_mediatype::ProviderRuby"
  end
  
  it "should return false on inexistant mediatypes" do
    resource = Puppet::Type.type(:zabbix_mediatype).new({
      :description => 'not my rspec mediatype',
    })
    Puppet.settings[:config]= "#{File.dirname(__FILE__)}/../../../../tests/etc/puppet.conf"
    resource.provider().exists?().should be_false
  end
  
  it "should create a mediatype, find it and delete it again" do
    resource = Puppet::Type.type(:zabbix_mediatype).new({
      :description => 'my rspec mediatype'
    })
    Puppet.settings[:config]= "#{File.dirname(__FILE__)}/../../../../tests/etc/puppet.conf"
    resource.provider().create()
    resource.provider().exists?().should be_true
    resource.provider().destroy()
    resource.provider().exists?().should be_false
  end
end