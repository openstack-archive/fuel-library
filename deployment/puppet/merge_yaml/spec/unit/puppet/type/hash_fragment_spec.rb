require 'spec_helper'

describe Puppet::Type.type(:hash_fragment) do
  subject do
    Puppet::Type.type(:hash_fragment)
  end

  before(:each) do
    puppet_debug_override
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  %w(name hash_name priority data type content).each do |param|
    it "should have a #{param} parameter" do
      expect(subject.validparameter?(param.to_sym)).to be_truthy
    end

    it "should have documentation for its #{param} parameter" do
      expect(subject.paramclass(param.to_sym).doc).to be_a String
    end
  end

end
