require File.join File.dirname(__FILE__), '../test_common.rb'
require 'rubygems'
require 'openstack'

class VcenterHooksPostTest < Test::Unit::TestCase

  def get_az_name
    vc = TestCommon::Settings::lookup 'vcenter'
    return vc['computes'][0]['availability_zone_name']
  end

  def get_credentials
    access = TestCommon::Settings::lookup 'access'
    mvip = TestCommon::Settings::lookup 'management_vip'
    auth_url = 'http://' + mvip + ':5000/v2.0/'
    return {:user => access["user"], :pass => access["password"],
            :authtenant => access["tenant"], :auth_url => auth_url,
            :api_key => access["password"]}
  end

  def check_az(creds, az_name)
    os = OpenStack::Connection.create({:username => creds[:user], :auth_method => creds[:pass],
                                       :authtenant => creds[:authtenant], :auth_url => creds[:auth_url],
                                       :api_key => creds[:api_key]})
     os.servers_detail.find_index { |s| s[:"OS-EXT-AZ:availability_zone"] == az_name}
  end

  def test_az
    assert check_az(get_credentials, get_az_name), 'Availability zone for vCenter does not created!'
  end

  def test_process
    assert TestCommon::Process.running?('/etc/nova/nova-compute.d/vmware'), 'Process nova-compute --config-file=/etc/nova/nova-compute.d/vmware-*_*.conf is not running!'
  end

end
