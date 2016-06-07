require 'spec_helper'

describe 'generate_apt_sources' do

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
    is_expected.not_to be_nil
  end

  it 'should expect 1 argument' do
    is_expected.to run.with_params().and_raise_error(ArgumentError)
  end

  it 'should expect array as given argument' do
    is_expected.to run.with_params('foobar').and_raise_error(Puppet::ParseError)
  end

  it 'should return apt::source compatible hash' do
    is_expected.to run.with_params(input).and_return(output)
  end
end
