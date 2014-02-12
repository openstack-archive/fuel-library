
describe "zabbix_template_item" do
  let(:provider) { Puppet::Type.type(:zabbix_template_item) }
  
  it "should get defined as provider" do
  
    resource = Puppet::Type.type(:zabbix_template_item).new({
      :name => 'my rspec template item',
    })
    resource.provider.class.to_s.should == "Puppet::Type::Zabbix_template_item::ProviderRuby"
  end
  
  
  it "should return false on inexistant template items" do
    resource = Puppet::Type.type(:zabbix_template_item).new({
      :name => 'not my rspec template item',
    })
    Puppet.settings[:config]= "#{File.dirname(__FILE__)}/../../../../tests/etc/puppet.conf"
    resource.provider().exists?().should be_false
  end

  it "should return true on existant template items" do
    template = Puppet::Type.type(:zabbix_template).new({
      :name => 'my rspec items template',
    })
    resource = Puppet::Type.type(:zabbix_template_item).new({
      :name => 'my existing rspec item',
      :key => 'rspec.template.item.existing',
      :template => 'my rspec items template'
    })
    Puppet.settings[:config]= "#{File.dirname(__FILE__)}/../../../../tests/etc/puppet.conf"
    if not template.provider().exists?
      template.provider().create()
    end
    if not resource.provider().exists?
      resource.provider().create()
    end
    resource.provider().exists?.should be_true
  end
  
  it "should create a template item, find it and delete it again" do
    template = Puppet::Type.type(:zabbix_template).new({
      :name => 'my rspec items template',
    })
    resource = Puppet::Type.type(:zabbix_template_item).new({
      :name => 'my rspec item',
      :key => 'rspec.template.item',
      :template => 'my rspec items template'
    })
    Puppet.settings[:config]= "#{File.dirname(__FILE__)}/../../../../tests/etc/puppet.conf"
    if not template.provider.exists?
      template.provider().create()
    end
    resource.provider().create()
    resource.provider().exists?.should be_true
    resource.provider().destroy()
    resource.provider().exists?.should be_false
  end
end