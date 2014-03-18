require 'puppet'
require 'spec_helper'
require 'puppet/provider/zabbix_host/ruby'

cls = Puppet::Type.type(:zabbix_host).provider(:ruby)
fake_api = {"username" => "username",
            "password" => "password",
            "endpoint" => "http://endpoint"}
resource = Puppet::Type.type(:zabbix_host).new(:name => 'test', :host => 'test', :groups => ['test'], :ip => '192.168.0.1', :api => fake_api)
provider = resource.provider

describe cls do

  it 'should fail to create a zabbix host if any of provided groups do not exist' do
    provider.expects(:get_hostgroup).returns([])
    expect {
      provider.create
    }.to raise_error(Puppet::Error, /Group.+?does not exist/)
  end

end
