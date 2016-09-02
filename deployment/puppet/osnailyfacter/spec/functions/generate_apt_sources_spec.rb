require 'spec_helper'

describe 'generate_apt_sources' do

  let(:input) {
    [
      {'name'     => 'ubuntu',
       'section'  => 'main universe multiverse',
       'uri'      => 'http://archive.ubuntu.com/ubuntu/',
       'priority' => nil,
       'suite'    => 'xenial',
       'type'     => 'deb'},
      {'name'     => 'ubuntu-updates',
       'section'  => 'main universe multiverse',
       'uri'      => 'http://archive.ubuntu.com/ubuntu/',
       'priority' => nil,
       'suite'    => 'xenial-updates',
       'type'     => 'deb'},
      {'name'     => 'ubuntu-security',
       'section'  => 'main universe multiverse',
       'uri'      => 'http://archive.ubuntu.com/ubuntu/',
       'priority' => nil,
       'suite'    => 'xenial-security',
       'type'     => 'deb'},
    ]
  }

  let (:output) {
    {
      'ubuntu' =>
         {
           'repos'    => 'main universe multiverse',
           'release'  => 'xenial',
           'location' => 'http://archive.ubuntu.com/ubuntu/'
         },
      'ubuntu-updates' =>
         {
           'repos'    => 'main universe multiverse',
           'release'  => 'xenial-updates',
           'location' => 'http://archive.ubuntu.com/ubuntu/'
         },
     'ubuntu-security' =>
         {
           'repos'    => 'main universe multiverse',
           'release'  => 'xenial-security',
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
