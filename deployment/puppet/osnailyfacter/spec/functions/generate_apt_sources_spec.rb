require 'spec_helper'

describe 'generate_apt_sources' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  let(:subject) {
    Puppet::Parser::Functions.function(:generate_apt_sources)
  }

  let(:input) {
    [
      {'name'     => 'ubuntu',
       'section'  => 'main universe multiverse',
       'uri'      => 'http://archive.ubuntu.com/ubuntu/',
       'priority' => nil,
       'suite'    => 'trusty',
       'type'     => 'deb'},
      {'name'     => 'ubuntu-updates',
       'section'  => 'main universe multiverse',
       'uri'      => 'http://archive.ubuntu.com/ubuntu/',
       'priority' => nil,
       'suite'    => 'trusty-updates',
       'type'     => 'deb'},
      {'name'     => 'ubuntu-security',
       'section'  => 'main universe multiverse',
       'uri'      => 'http://archive.ubuntu.com/ubuntu/',
       'priority' => nil,
       'suite'    => 'trusty-security',
       'type'     => 'deb'},
    ]
  }

  let (:output) {
    {
      'ubuntu' =>
         {
           'repos'    => 'main universe multiverse',
           'release'  => 'trusty',
           'location' => 'http://archive.ubuntu.com/ubuntu/'
         },
      'ubuntu-updates' =>
         {
           'repos'    => 'main universe multiverse',
           'release'  => 'trusty-updates',
           'location' => 'http://archive.ubuntu.com/ubuntu/'
         },
     'ubuntu-security' =>
         {
           'repos'    => 'main universe multiverse',
           'release'  => 'trusty-security',
           'location' => 'http://archive.ubuntu.com/ubuntu/'
         },
    }
  }

  it 'should exist' do
    expect(subject).to eq 'function_generate_apt_sources'
  end

  it 'should expect 1 argument' do
    expect { scope.function_generate_apt_sources([]) }.to raise_error(ArgumentError)
  end

  it 'should expect array as given argument' do
    expect { scope.function_generate_apt_sources(['foobar']) }.to raise_error(Puppet::ParseError)
  end

  it 'should return apt::source compatible hash' do
    expect(scope.function_generate_apt_sources([input])).to eq(output)
  end
end
