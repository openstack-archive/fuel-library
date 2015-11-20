require 'spec_helper'

describe 'generate_apt_pins' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  class FakeResponse
    def body
      content = <<EOS
Origin: Mirantis
Label: mos9.0
Suite: mos9.0
Codename: mos9.0
Date: Wed, 23 Dec 2015 16:23:31 UTC
Architectures: amd64 i386
Components: main restricted
EOS
    content
    end
  end


  let(:subject) {
    Puppet::Parser::Functions.function(:generate_apt_pins)
  }

  let(:input) {
    [
      {'name'     => 'ubuntu',
       'section'  => 'main universe multiverse',
       'uri'      => 'http://archive.ubuntu.com/ubuntu/',
       'priority' => nil,
       'suite'    => 'trusty',
       'type'     => 'deb'},
      {'name'     => 'mos',
       'section'  => 'main restricted',
       'uri'      => 'http://mirror.fuel-infra.org/mos-repos/ubuntu/9.0/',
       'priority' => 1050,
       'suite'    => 'mos9.0',
       'type'     => 'deb'},
    ]
  }

  let (:output) {
    {'mos' =>
      {
        'priority'   => 1050,
        'originator' => 'Mirantis',
        'label'      => 'mos9.0',
        'release'    => 'mos9.0',
        'codename'   => 'mos9.0'
      },
    }
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

  it 'should return apt::pin compatible hash' do
    Net:HTTP.stub(:get_response).with('http://mirror.fuel-infra.org/mos-repos/ubuntu/9.0/dists/mos9.0/Release').and_return(FakeResponse.new)
    expect(scope.function_generate_apt_pins([input])).to eq(output)
  end
end
