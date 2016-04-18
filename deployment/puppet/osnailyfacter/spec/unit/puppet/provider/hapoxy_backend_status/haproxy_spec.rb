require 'puppet'

describe Puppet::Type.type(:haproxy_backend_status).provider(:haproxy) do
  let (:resource) do
    Puppet::Type::Haproxy_backend_status.new(
      {
          :name   => 'test',
          :socket => '/var/run/haproxy.sock',
      }
    )
  end

  let (:provider) do
    provider = resource.provider
    if ENV['SPEC_PUPPET_DEBUG']
      class << provider
        def debug(msg)
          puts msg
        end
      end
    end
    provider
  end

  let(:csv) {
<<eof
######
test,FRONTEND,,,0,0,8000,0,0,0,0,0,0,,,,,OPEN,,,,,,,,,1,18,0,,,,0,0,0,0,,,,0,0,0,0,0,0,,0,0,0,,,0,0,0,0,,,,,,,,
test,node-16,0,0,0,0,,0,0,0,,0,,0,0,0,0,UP,1,1,0,0,0,7403,0,,1,18,1,,0,,2,0,,0,L4OK,,0,0,0,0,0,0,0,0,,,,0,0,,,,,-1,,,0,0,0,0,
test,BACKEND,0,0,0,0,800,0,0,0,0,0,,0,0,0,0,UP,1,1,0,,0,7403,0,,1,18,0,,0,,1,0,,0,,,,0,0,0,0,0,0,,,,,0,0,0,0,0,0,-1,,,0,0,0,0,
test-down,FRONTEND,,,0,0,8000,0,0,0,0,0,0,,,,,OPEN,,,,,,,,,1,8,0,,,,0,0,0,0,,,,0,0,0,0,0,0,,0,0,0,,,0,0,0,0,,,,,,,,
test-down,node-16,0,0,0,0,,0,0,0,,0,,0,0,0,0,DOWN,1,1,0,1,1,7402,7402,,1,8,1,,0,,2,0,,0,L4CON,,0,0,0,0,0,0,0,0,,,,0,0,,,,,-1,Connection refused,,0,0,0,0,
test-down,BACKEND,0,0,0,0,800,0,0,0,0,0,,0,0,0,0,DOWN,0,0,0,,1,7402,7402,,1,8,0,,0,,1,0,,0,,,,0,0,0,0,0,0,,,,,0,0,0,0,0,0,-1,,,0,0,0,0,
test-init,FRONTEND,,,0,0,8000,0,0,0,0,0,0,,,,,OPEN,,,,,,,,,1,8,0,,,,0,0,0,0,,,,0,0,0,0,0,0,,0,0,0,,,0,0,0,0,,,,,,,,
test-init,node-16,0,0,0,0,,0,0,0,,0,,0,0,0,0,INIT,1,1,0,1,1,7402,7402,,1,8,1,,0,,2,0,,0,L4CON,,0,0,0,0,0,0,0,0,,,,0,0,,,,,-1
test-init,BACKEND,0,0,0,0,800,0,0,0,0,0,,0,0,0,0,INIT,0,0,0,,1,7402,7402,,1,8,0,,0,,1,0,,0,,,,0,0,0,0,0,0,,,,,0,0,0,0,0,0,-1,,,0,0,0,0,
eof
  }

  let(:stats) {
    {
        'test' => 'UP',
        'test-down' => 'DOWN',
        'test-init' => 'INIT',
    }
  }

  before(:each) do
    provider.stubs(:stats).returns(stats)
    provider.stubs(:get_haproxy_debug_report).returns nil
  end

  it 'should parse csv data' do
    provider.expects(:csv).returns csv
    provider.unstub(:stats)
    expect(provider.stats).to eq(stats)
  end

  it 'should get status for :present or :absent checks for present backend' do
    resource[:ensure] = 'present'
    resource[:name] = 'test'
    expect(provider.ensure).to eq(:present)
  end

  it 'should get status for :present or :absent checks for absent backend' do
    resource[:ensure] = 'present'
    resource[:name] = 'test2'
    expect(provider.ensure).to eq(:absent)
  end

  it 'should get status for :up and :down for up backend' do
    resource[:ensure] = 'up'
    resource[:name] = 'test'
    expect(provider.ensure).to eq(:up)
  end

  it 'should get status for :up and :down for down backend' do
    resource[:ensure] = 'up'
    resource[:name] = 'test-down'
    expect(provider.ensure).to eq(:down)
  end

  it 'should get status for :up and :down for missing backend' do
    resource[:ensure] = 'up'
    resource[:name] = 'test2'
    expect(provider.ensure).to eq(:absent)
  end

  it 'should treat an unknown status as :present' do
    resource[:ensure] = 'up'
    resource[:name] = 'test-init'
    expect(provider.ensure).to eq(:present)
  end

  it 'should treat a missing backend as :absent' do
    resource[:name] = 'mytest'
    resource[:ensure] = 'up'
    expect(provider.ensure).to eq(:absent)
  end

  it 'should print the haproxy backend status report when status is extracted' do
    provider.expects(:get_haproxy_debug_report)
    provider.ensure
  end

  it 'should print the haproxy backend status report when waiting have finished' do
    provider.expects(:get_haproxy_debug_report)
    provider.ensure = :up
  end

  it 'should fail when there is no retries left and print the haproxy backend status' do
    resource[:name] = 'test-down'
    resource[:step] = 0
    resource[:count] = 3
    provider.expects(:get_haproxy_debug_report).once
    provider.expects(:stats).returns(stats).times(3)
    expect {
      provider.ensure = :up
    }.to raise_error
  end


end
