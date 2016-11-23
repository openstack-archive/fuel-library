require 'spec_helper'

describe 'get_packages_for_upgrade' do
  # TODO: this function is beyond redemption
  #
  # let(:source_path) do
  #   '/etc/fuel/maintenance/apt/sources.list.d/'
  # end
  #
  # let(:output) do
  #   { 'ntp' => {'ensure' => 'latest' } }
  # end
  #
  # let(:cmd) do
  #   "apt-get --just-print -o Dir::etc::sourcelist='-' -o Dir::Etc::sourceparts='#{source_path}' dist-upgrade -qq"
  # end
  #
  # let(:cmd_output) do
  #   'Inst ntp [1:4.2.6.p5+dfsg-3ubuntu2.14.04.8] (2:4.2.6.p5+dfsg-3~u14.04+mos1 mos9.0:mos9.0-proposed [amd64])\n'
  # end
  #
  # it 'should get packages hash' do
  #   scope.stubs(:file_exists).with(source_path).returns(true)
  #   scope.stubs(:`).with(cmd).returns(cmd_output)
  #   is_expected.to run.with_params(source_path).and_return(output)
  # end
  #
  # it 'should get empty packages hash if osfamily is not Debian' do
  #   Facter.expects(:value).with(:osfamily).returns('redhat')
  #   is_expected.to run.with_params(source_path).and_return({})
  # end
end
