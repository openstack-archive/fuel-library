require 'puppet'
require 'puppet/type/ceilometer_radosgw_user'

describe Puppet::Type.type(:ceilometer_radosgw_user) do

  before :each do
    @rgw_user = Puppet::Type.type(:ceilometer_radosgw_user).new(
      :name => 'ceilometer',
      :caps => {}
    )
  end

  it 'should require a name' do
    expect {
      Puppet::Type.type(:ceilometer_radosgw_user).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should contain resource hash' do
    expect {
      @rgw_user[:caps] = 'string => data'
    }.to raise_error(Puppet::Error, /Caps should contain hash$/)
  end

  it 'should accept an caps data' do
    caps = {
      'buckets' => 'read',
      'usage' => 'read'
    }
    @rgw_user[:caps] = caps
    expect(@rgw_user[:caps]).to eq(caps)
  end

end
