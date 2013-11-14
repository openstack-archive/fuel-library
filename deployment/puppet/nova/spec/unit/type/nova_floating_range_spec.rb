require 'puppet'

describe 'Puppet::Type.newtype(:nova_floating_range)' do
  before :each do
    @nova_floating_range = Puppet::Type.type(:nova_floating_range).new(:name => '10.0.0.1-10.0.0.254')
  end

  it 'should not expect a name without ip range' do
    expect {
      Puppet::Type.type(:nova_floating_range).new(:name => 'foo')
    }.to raise_error(Puppet::Error, /does not look/)
  end

  it 'pull should be "nova" by default' do
    @nova_floating_range[:pool].should == 'nova'
  end

  it 'auth url should be url' do
    expect {     @nova_floating_range[:auth_url] = 'h ttp://192.168.1.1:5000/v2.0/'
    }.to raise_error(Puppet::Error, /does not look/)
  end

  it 'api retries should be numeric' do
    expect {     @nova_floating_range[:api_retries] = '3b'
    }.to raise_error(Puppet::Error, /does not look/)
  end
end
