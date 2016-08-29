require 'spec_helper'
require 'yaml'

describe 'get_packages_to_upgrade' do

  let(:path) do
    '/etc/fuel/maintenance/apt/sources.list.d/'
  end

  let(:output) do
    { 'ntp' => {'ensure' => 'latest' } }
  end

  let(:cmd) do
    "apt-get --just-print -o Dir::etc::sourcelist='-' -o Dir::Etc::sourceparts='#{path}' dist-upgrade -qq"
  end

  it 'should get packages' do
    File.expects(:exist?).with(path).returns(true)
    x.should_receive(:`).once.with(cmd).returns('Inst ntp [1:4.2.6.p5+dfsg-3ubuntu2.14.04.8] (2:4.2.6.p5+dfsg-3~u14.04+mos1 mos9.0:mos9.0-proposed [amd64])\n')
    is_expected.to run.with_params(path).and_return(output)
  end
end
