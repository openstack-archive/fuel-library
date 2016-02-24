require 'spec_helper'

describe Puppet::Type.type(:cgclassify).provider(:cgclassify) do

  let(:list_all_cgroups) {
%q(cpuset:/
cpu:/
cpu:/group_cx
cpuacct:/
memory:/
memory:/group_mx
devices:/
freezer:/
blkio:/
perf_event:/
hugetlb:/
)
  }

  let(:parsed_procs) { %w(service_x) }

  let(:resource) {
    Puppet::Type.type(:cgclassify).new(
      { 
        :ensure   => :present,
        :name     => 'service_x',
        :cgroup   => ['memory:/group_mx', 'cpu:/group_cx'],
        :provider => described_class.name,
      }
    )
  }

  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }

  before :each do
    provider.class.stubs(:lscgroup).returns(list_all_cgroups)
    provider.class.stubs(:cgclassify).returns(true)
    provider.class.stubs(:pidof).with('-x', 'service_x').returns("1 2\n")

    %w(1 2).each do |pid|
      provider.class.stubs(:ps).with('-p', pid, '-o', 'comm=').returns('service_x')
    end

    list_all_cgroups.split("\n").reject { |cg| cg.end_with? '/' }.each do |cg|
      File.stubs(:open).with("/sys/fs/cgroup/#{cg.delete ':'}/tasks").returns(StringIO.new("1\n2\n")) 
    end
  end

  describe '#self.instances' do
    it 'returns an array of procs/tasks in cgroups' do
      procs = provider.class.instances.collect {|x| x.name }
      expect(parsed_procs).to match_array(procs)
    end
  end

  describe '#create' do
    it 'moves tasks to given cgroups' do
      provider.expects(:cgclassify_cmd).with(['memory:/group_mx', 'cpu:/group_cx'], 'service_x')
      provider.create
    end
  end

  describe '#destroy' do
    it 'moves tasks to root cgroup' do
      provider.expects(:cgclassify_cmd)
      provider.destroy
    end
  end

  describe '#exists?' do
    it 'checks if tasks are in cgroups' do
      expect(instance.exists?).to eql true
    end
  end

  describe '#cgroup=' do
    it 'changes nothing' do
      provider.set(
        :ensure => :present,
        :name   => 'service_x',
        :cgroup => ['memory:/group_mx', 'cpu:/group_cx'],
      )
      provider.expects(:cgclassify_cmd).times(0)
      provider.cgroup=(['memory:/group_mx', 'cpu:/group_cx'])
    end

    it 'add tasks to cgroups' do
      resource.provider.set(
        :ensure => :present,
        :name   => 'service_x',
        :cgroup => ['memory:/group_mx'],
      )
      provider.expects(:cgclassify_cmd).with(['cpu:/group_cx'], 'service_x')
      provider.cgroup=(['memory:/group_mx', 'cpu:/group_cx'])
    end

    it 'removes tasks from cgroups' do
      resource.provider.set(
        :ensure => :present,
        :name   => 'service_x',
        :cgroup => ['memory:/group_mx', 'cpu:/group_cx'],
      )
      provider.expects(:cgclassify_cmd).with(['memory:/'], 'service_x')
      provider.cgroup=(['cpu:/group_cx'])
    end

    it 'exchanges a cgroup' do
      resource.provider.set(
        :ensure => :present,
        :name   => 'service_x',
        :cgroup => ['memory:/group_mx', 'cpu:/group_cx'],
      )
      provider.expects(:cgclassify_cmd).with(['cpu:/', 'blkio:/group_bx'], 'service_x')
      provider.cgroup=(['memory:/group_mx', 'blkio:/group_bx'])
    end
  end

end
