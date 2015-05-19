require 'spec_helper'

describe Puppet::Type.type(:sysfs_config_value).provider(:ruby) do

  let(:resource) do
    Puppet::Type.type(:sysfs_config_value).new(
        :name => '/etc/sysfs.d/scheduler.conf',
        :sysfs => '/sys/block/sd*/queue/scheduler',
        :exclude => '/sys/block/sdc/queue/scheduler',
        :value => 'noop',
    )
  end

  let(:provider) do
    provider = resource.provider
    if ENV['SPEC_PUPPET_DEBUG']
      class << provider
        def debug(str)
          puts str
        end
      end
    end
    provider
  end

  subject { provider }

  before(:each) do
    allow(subject).to receive(:file_mkdir)
    allow(subject).to receive(:file_write)
    allow(subject).to receive(:file_exists?)
    allow(subject).to receive(:file_remove)
    allow(subject).to receive(:file_read)
  end

  it 'should exist' do
    expect(subject).to be_a Puppet::Provider
  end

  context 'ensurable' do
    it 'should check if file exists' do
      expect(subject).to receive(:file_exists?).and_return(true)
      expect(subject.exists?).to be true
    end

    it 'can create a file and parent directory' do
      resource[:content] = '123'
      expect(subject).to receive(:file_write).with('123')
      expect(subject).to receive(:file_mkdir)
      expect(subject.file_base_dir).to eq '/etc/sysfs.d'
      subject.create
    end

    it 'can remove a file' do
      expect(subject).to receive(:file_remove)
      subject.destroy
    end
  end

  context 'content' do
    it 'can read file content' do
      expect(subject).to receive(:file_read).and_return('123')
      expect(subject.content).to eq '123'
    end

    it 'can write file content' do
      expect(subject).to receive(:file_write).with('123')
      subject.content = '123'
    end
  end

  context 'content generation' do
    before(:each) do
      allow(subject).to receive(:glob).with('/sys/block/sd*/queue/scheduler').and_return %w(
        /sys/block/sda/queue/scheduler
        /sys/block/sdb/queue/scheduler
        /sys/block/sdc/queue/scheduler
      )
      allow(subject).to receive(:glob).with('/sys/block/sda/queue/scheduler').and_return %w(
        /sys/block/sda/queue/scheduler
      )
      allow(subject).to receive(:glob).with('/sys/block/sdb/queue/scheduler').and_return %w(
        /sys/block/sdb/queue/scheduler
      )
      allow(subject).to receive(:glob).with('/sys/block/sdc/queue/scheduler').and_return %w(
        /sys/block/sdc/queue/scheduler
      )
    end

    it 'can get a list of sysfs nodes using "sysfs" and "exclude"' do
      expect(subject.sysfs_nodes).to match_array %w(
        /sys/block/sda/queue/scheduler
        /sys/block/sdb/queue/scheduler
      )
    end

    it 'can get a sysfs node value either as a string or as a hash' do
      resource[:value] = '123'
      expect(subject.sysfs_node_value '/sys/block/sda/queue/scheduler').to eq '123'
      resource[:value] = { 'sda' => '234' }
      expect(subject.sysfs_node_value '/sys/block/sda/queue/scheduler').to eq '234'
      resource[:value] = { 'default' => '345' }
      expect(subject.sysfs_node_value '/sys/block/sda/queue/scheduler').to eq '345'
    end

    it 'can generate new config file content' do
      expect(resource).to receive(:generate_content?).and_return(true)
      resource[:content] = ''
      subject.generate_file_content
      expect(resource[:content]).to eq <<-eos
block/sda/queue/scheduler = noop
block/sdb/queue/scheduler = noop
      eos
    end

    it 'can use values provided as a hash' do
      expect(resource).to receive(:generate_content?).and_return(true)
      resource[:content] = ''
      resource[:value] = { 'sdb' => 'deadline', 'default' => 'noop' }
      subject.generate_file_content
      expect(resource[:content]).to eq <<-eos
block/sda/queue/scheduler = noop
block/sdb/queue/scheduler = deadline
      eos
    end

    it 'can use and array of "sysfs" values' do
      expect(resource).to receive(:generate_content?).and_return(true)
      resource[:content] = ''
      resource[:sysfs] = %w(
        /sys/block/sda/queue/scheduler
        /sys/block/sdb/queue/scheduler
      )
      subject.generate_file_content
      expect(resource[:content]).to eq <<-eos
block/sda/queue/scheduler = noop
block/sdb/queue/scheduler = noop
      eos
    end

    it 'can use and array of "exclude" values' do
      expect(resource).to receive(:generate_content?).and_return(true)
      resource[:content] = ''
      resource[:sysfs] = %w(
        /sys/block/sda/queue/scheduler
        /sys/block/sdb/queue/scheduler
        /sys/block/sdc/queue/scheduler
      )
      resource[:exclude] = %w(
        /sys/block/sdc/queue/scheduler
      )
      subject.generate_file_content
      expect(resource[:content]).to eq <<-eos
block/sda/queue/scheduler = noop
block/sdb/queue/scheduler = noop
      eos
    end

    it 'will not generate content if the type tells not to' do
      expect(resource).to receive(:generate_content?).and_return(false)
      resource[:content] = ''
      subject.generate_file_content
      expect(resource[:content]).to eq ''
    end
  end

end
