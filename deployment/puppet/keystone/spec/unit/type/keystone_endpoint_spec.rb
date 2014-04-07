describe Puppet::Type.type(:keystone_endpoint) do

  it 'should fail when the namevar does not contain a region' do
    expect do
      Puppet::Type.type(:keystone_endpoint).new(:name => 'foo')
    end.to raise_error(Puppet::Error, /Invalid value/)
  end

end
