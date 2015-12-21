require 'spec_helper'

provider_class = Puppet::Type.type(:ceilometer_radosgw_user).provider(:user)

describe provider_class do

  let :user_attrs do
    {
      :name   => 'ceilometer',
      :caps   => {'buckets' => 'read', 'usage' => 'read'},
      :ensure => 'present',
    }
  end

  let :keys do
    {
       'access_key' => 'accEss',
       'secret_key' => 'sEcrEt'
    }
  end

  let :rgw_output do
    {
      'keys' => [
        { 'user' => 'ceilometer' }.merge(keys)
      ]
    }
  end

  let :cmd do
    ['user', 'info', "--uid=#{user_attrs[:name]}"]
  end

  let :resource do
    Puppet::Type::Ceilometer_radosgw_user.new(user_attrs)
  end

  let :provider do
    provider_class.new(resource)
  end

  it 'checks that resource does not exist' do
    provider.class.stubs(:rgw_adm)
                   .with(cmd)
                   .raises(Puppet::ExecutionFailure, 'could not fetch user info: no user info saved')

    expect(provider.exists?).to eq false
  end

  it 'returns ini_filename' do
    expect(provider.ini_filename).to eq("/etc/ceilometer/ceilometer.conf")
  end

  it 'gets access keys from config' do
    mock = {'rgw_admin_credentials' => keys}
    File.expects(:exists?).with('/etc/ceilometer/ceilometer.conf').returns(true)
    Puppet::Util::IniConfig::File.expects(:new).returns(mock)
    mock.expects(:read).with('/etc/ceilometer/ceilometer.conf')
    expect(provider.access_keys_from_config).to eq(keys)
  end

  it 'gets radosgw user keys' do
    provider.class.stubs(:rgw_adm).with(cmd).returns(rgw_output)
    expect(provider.radosgw_user_keys).to eq(keys)
  end

end
