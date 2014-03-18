require 'puppet'
require 'spec_helper'
require 'puppet/provider/zabbix_template_link/ruby'

cls = Puppet::Type.type(:zabbix_template_link).provider(:ruby)
fake_api = {"username" => "username",
            "password" => "password",
            "endpoint" => "http://endpoint"}
resource = Puppet::Type.type(:zabbix_template_link).new(:name => 'test link', :host => 'test', :template => 'test', :api => fake_api)
provider = resource.provider

describe cls do

  it 'should fail if provided host does not exist' do
    provider.expects(:auth).with(fake_api).returns("auth_hash")
    provider.expects(:get_host).returns([])
    expect {
      provider.exists?
    }.to raise_error(Puppet::Error, /Host.+?does not exist/)
  end

  it 'should fail if provided template does not exist' do
    provider.expects(:auth).with(fake_api).returns("auth_hash")
    provider.expects(:get_host).returns(['0'])
    provider.expects(:api_request).with(fake_api,
                                        {:method => "template.get",
                                         :params => {:filter => {:host => [resource[:template]]}}}).returns([])
    expect {
      provider.exists?
    }.to raise_error(Puppet::Error, /Template.+?does not exist/)
  end

end
