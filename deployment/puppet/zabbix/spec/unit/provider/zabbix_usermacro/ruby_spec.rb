require 'puppet'
require 'spec_helper'
require 'puppet/provider/zabbix_usermacro/ruby'

cls = Puppet::Type.type(:zabbix_usermacro).provider(:ruby)
fake_api = {"username" => "username",
            "password" => "password",
            "endpoint" => "http://endpoint"}
resource = Puppet::Type.type(:zabbix_usermacro).new(:name => 'test', :host => 'test', :macro => 'test', :value => 'test', :api => fake_api)
provider = resource.provider

describe cls do

  it 'should fail if it is not global and provided host does not exist' do
    resource[:global] = :false
    provider.expects(:auth).with(fake_api).returns("auth_hash")
    provider.expects(:get_host).returns([])
    expect {
      provider.exists?
    }.to raise_error(Puppet::Error, /Host.+?does not exist/)
  end

  it 'should get a list of global macros when global is true' do
    resource[:global] = :true
    body = {:method => "usermacro.get",
            :params => {:globalmacro => true,
                        :output => "extend"}}
    provider.expects(:auth).with(fake_api).returns("auth_hash")
    provider.expects(:api_request).with(fake_api, body).returns([{"macro" => "macro"}])
    provider.exists?
  end

end
