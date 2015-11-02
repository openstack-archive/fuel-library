require 'spec_helper'

describe Puppet::Type.type(:hiera_config) do

  subject do
    Puppet::Type.type(:hiera_config)
  end

  let(:params) do
    {
      :name => '/etc/hiera.yaml',
      :hierarchy => %w(base additional),
    }
  end

  it 'should be able to create an instance' do
    expect(subject.new params).not_to be_falsey
  end

  [:logger, :data_dir, :hierarchy, :hierarchy_override, :merge_behavior].each do |param|
    it "should have a #{param} parameter" do
      expect(subject.valid_parameter?(param)).to be_truthy
    end
  end

end


