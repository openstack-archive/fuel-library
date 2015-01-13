require 'puppet'

provider_class = Puppet::Type.type(:haproxy_backend_status).provider(:haproxy)

describe provider_class do
  before :each do
    @resource = Puppet::Type::Haproxy_backend_status.new(
        {
            :name   => 'test',
            :socket => '/var/run/haproxy.sock',
        })
    @provider = provider_class.new(@resource)
  end

  let(:csv) {
<<eof
test,FRONTEND,,,0,0,8000,0,0,0,0,0,0,,,,,OPEN,,,,,,,,,1,18,0,,,,0,0,0,0,,,,0,0,0,0,0,0,,0,0,0,,,0,0,0,0,,,,,,,,
test,node-16,0,0,0,0,,0,0,0,,0,,0,0,0,0,UP,1,1,0,0,0,7403,0,,1,18,1,,0,,2,0,,0,L4OK,,0,0,0,0,0,0,0,0,,,,0,0,,,,,-1,,,0,0,0,0,
test,BACKEND,0,0,0,0,800,0,0,0,0,0,,0,0,0,0,UP,1,1,0,,0,7403,0,,1,18,0,,0,,1,0,,0,,,,0,0,0,0,0,0,,,,,0,0,0,0,0,0,-1,,,0,0,0,0,
test-down,FRONTEND,,,0,0,8000,0,0,0,0,0,0,,,,,OPEN,,,,,,,,,1,8,0,,,,0,0,0,0,,,,0,0,0,0,0,0,,0,0,0,,,0,0,0,0,,,,,,,,
test-down,node-16,0,0,0,0,,0,0,0,,0,,0,0,0,0,DOWN,1,1,0,1,1,7402,7402,,1,8,1,,0,,2,0,,0,L4CON,,0,0,0,0,0,0,0,0,,,,0,0,,,,,-1,Connection refused,,0,0,0,0,
test-down,BACKEND,0,0,0,0,800,0,0,0,0,0,,0,0,0,0,DOWN,0,0,0,,1,7402,7402,,1,8,0,,0,,1,0,,0,,,,0,0,0,0,0,0,,,,,0,0,0,0,0,0,-1,,,0,0,0,0,
eof
  }

  let(:stats) {
    {
        'test' => :up,
        'test-down' => :down,
    }
  }

  it 'should get status for :present or :absent checks for present backend' do
    @resource[:ensure] = 'present'
    @resource[:name] = 'test'
    expect(@provider).to receive(:stats).at_least(:once).and_return(stats)
    expect(@provider.ensure).to eq(:present)
  end

  it 'should get status for :present or :absent checks for absent backend' do
    @resource[:ensure] = 'present'
    @resource[:name] = 'test2'
    expect(@provider).to receive(:stats).at_least(:once).and_return(stats)
    expect(@provider.ensure).to eq(:absent)
  end

  it 'should get status for :up and :down for up backend' do
    @resource[:ensure] = 'up'
    @resource[:name] = 'test'
    expect(@provider).to receive(:stats).at_least(:once).and_return(stats)
    expect(@provider.ensure).to eq(:up)
  end

  it 'should get status for :up and :down for down backend' do
    @resource[:ensure] = 'up'
    @resource[:name] = 'test-down'
    expect(@provider).to receive(:stats).at_least(:once).and_return(stats)
    expect(@provider.ensure).to eq(:down)
  end

  it 'should get status for :up and :down for missing backend' do
    @resource[:ensure] = 'up'
    @resource[:name] = 'test2'
    expect(@provider).to receive(:stats).at_least(:once).and_return(stats)
    expect(@provider.ensure).to eq(:absent)
  end

  it 'should detect missing backend' do
    @resource[:name] = 'mytest'
    @resource[:ensure] = 'up'
    expect(@provider).to receive(:stats).at_least(:once).and_return(stats)
    expect(@provider.exists?).to eq(false)
    expect(@provider.ensure).to eq(:absent)
  end

  it 'should parse csv data' do
    expect(@provider).to receive(:csv).at_least(:once).and_return(csv)
    expect(@provider.stats).to eq(stats)
  end


end