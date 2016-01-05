require 'spec_helper'

describe 'generate_apt_pins' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  let(:subject) {
    Puppet::Parser::Functions.function(:generate_apt_pins)
  }

  it 'should exist' do
    expect(subject).to eq 'function_generate_apt_pins'
  end

  it 'should expect 1 argument' do
    expect { scope.function_generate_apt_pins([]) }.to raise_error(ArgumentError)
  end

  it 'should expect array as given argument' do
    expect { scope.function_generate_apt_pins(['foobar']) }.to raise_error(Puppet::ParseError)
  end
end
