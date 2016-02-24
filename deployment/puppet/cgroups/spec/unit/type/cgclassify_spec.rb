require 'puppet'
require 'puppet/type/cgclassify'

describe 'Puppet::Type.type(:cgclassify)' do

  before :each do
    @cgclassify = Puppet::Type.type(:cgclassify).new(
      :name   => 'service_x',
      :cgroup => ['memory:/group_x'],
      :sticky => true,
    )
  end

  it 'should require a name' do
    expect {
      Puppet::Type.type(:cgclassify).new({})
    }.to raise_error Puppet::Error, 'Title or name must be provided'
  end

  it 'should set sticky option' do
    expect(@cgclassify[:sticky]).to eq('--sticky')
  end

  context 'should reject invalid cgroup pattern' do
    it 'with swapped /:' do
      expect {
        @cgclassify[:cgroup] = ['memory/:group_x']
      }.to raise_error Puppet::ResourceError, /Invalid value/
    end

    it 'with absent controller' do
      expect {
        @cgclassify[:cgroup] = [':/group_x']
      }.to raise_error Puppet::ResourceError, /Invalid value/
    end
  end

  context 'should accept valid cgroup pattern' do
    it 'with cpu:/group_x' do
      @cgclassify[:cgroup] = ['cpu:/group_x']
      expect(@cgclassify[:cgroup]).to eq(['cpu:/group_x'])
    end

    it 'with two cgroups at once' do
      @cgclassify[:cgroup] = ['blkio:/', 'cpuset:/group_x']
      expect(@cgclassify[:cgroup]).to eq(['blkio:/', 'cpuset:/group_x'])
    end
  end

end
