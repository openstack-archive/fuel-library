require 'spec_helper'

describe Puppet::Type.type(:sysfs_config_value) do
  subject do
    Puppet::Type.type(:sysfs_config_value).new(
        :name => '/etc/sysfs.d/scheduler.conf',
        :sysfs => '/sys/block/sd*/queue/scheduler',
        :value => 'noop',
    )
  end

  it 'should exist' do
    expect(subject).to be_a Puppet::Type
  end

  [:name, :sysfs, :exclude, :value, :content].each do |param|
    it "should have '#{param}' parameter" do
      expect { subject[param] }.not_to raise_error
    end
  end

  it 'should permit the new content generation if there is no content and sysfs and value are present' do
    expect(subject.generate_content?).to be true
    subject[:content] = 'test'
    expect(subject.generate_content?).to be false
  end

  [:sysfs, :exclude].each do |param|
    it "should convert '#{param}' from a string to an array" do
      subject[param] = '123'
      expect(subject[param]).to eq ['123']
    end

    it "should pass '#{param}' array values as is" do
      subject[param] = ['123']
      expect(subject[param]).to eq ['123']
    end
  end

  it 'should accept "value" only as a string or a hash' do
    expect {
      subject[:value] = ['123']
    }.to raise_error
  end

  it 'should not allow to use the resource without either content or sysfs and value' do
    expect {
      Puppet::Type.type(:sysfs_config_value).new(
          :name => '/etc/sysfs/scheduler.conf',
      )
    }.to raise_error
  end

end
