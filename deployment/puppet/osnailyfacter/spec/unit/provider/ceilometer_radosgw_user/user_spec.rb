require 'spec_helper'

describe Puppet::Type.type(:ceilometer_radosgw_user).provider(:user) do

  let :caps do
    {'buckets' => 'read', 'usage' => 'read'}
  end

  let :resource do
    Puppet::Type.type(:ceilometer_radosgw_user).new(
      :name => 'ceilometer',
      :caps => caps,
    )
  end

  let :provider do
    resource.provider
  end

  it 'checks that resource does not exist' do
    expect(provider.exists?).to eq false
  end

  it 'returns ini_filename' do
    expect(provider.ini_filename).to eq("/etc/ceilometer/ceilometer.conf")
  end

  it 'gets access keys from config' do
    keys = {'access_key' => 'accEss', 'secret_key' => 'sEcrEt'}
    mock = {'rgw_admin_credentials' => keys}
    File.expects(:exists?).with('/etc/ceilometer/ceilometer.conf').returns(true)
    Puppet::Util::IniConfig::File.expects(:new).returns(mock)
    mock.expects(:read).with('/etc/ceilometer/ceilometer.conf')
    expect(provider.get_access_keys_from_config).to eq(keys)
  end

  it 'gets user keys' do
    keys = {'access_key' => 'accEss', 'secret_key' => 'sEcrEt'}
    rgw_output = {'keys' => [{'user' => 'ceilometer'}.merge(keys)]}
    cmd = ['user', 'info', "--uid=ceilometer"]

    provider.class.stubs(:rgw_adm).with(cmd).returns(rgw_output)
    expect(provider.get_user_keys).to eq(keys)
  end

end
