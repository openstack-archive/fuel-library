require 'spec_helper'

#CentOS

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_centos7) do

  before(:each) do
    puppet_debug_override()
  end

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'prefetching', 'centos')
  end

  context "parsing lnx provider" do
    let(:expected_data) { ['ifcfg-eth0', 'ifcfg-eth1.105'] }
    let(:target_files) {
        subject.class.stubs(:script_directory).returns(fixture_path)
        subject.class.target_files(fixture_path)
     }
    it { expect(target_files.length).to eq 2 }
    it { expect(target_files.map { |x| File.split(x)[1] } ).to match_array(expected_data) }
  end

end

describe Puppet::Type.type(:l23_stored_config).provider(:ovs_centos7) do

  before(:each) do
    puppet_debug_override()
  end

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'prefetching', 'centos')
  end

  context "parsing ovs provider" do
    let(:expected_data) { ['ifcfg-br-testovs'] }
    let(:target_files) {
        subject.class.stubs(:script_directory).returns(fixture_path)
        subject.class.target_files(fixture_path)
     }
    it { expect(target_files.length).to eq 1 }
    it { expect(target_files.map { |x| File.split(x)[1] } ).to match_array(expected_data) }
  end

end

#Ubuntu

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_ubuntu) do

  before(:each) do
    puppet_debug_override()
  end

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'prefetching', 'ubuntu')
  end

  context "parsing lnx provider" do
    let(:expected_data) { ['ifcfg-eth1', 'ifcfg-br-fw-admin'] }
    let(:target_files) {
        subject.class.stubs(:script_directory).returns(fixture_path)
        subject.class.target_files(fixture_path)
     }
    it { expect(target_files.length).to eq 2 }
    it { expect(target_files.map { |x| File.split(x)[1] } ).to match_array(expected_data) }
  end

end

describe Puppet::Type.type(:l23_stored_config).provider(:ovs_ubuntu) do

  before(:each) do
    puppet_debug_override()
  end

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'prefetching', 'ubuntu')
  end

  context "parsing ovs provider" do
    let(:expected_data) { ['ifcfg-br-floating'] }
    let(:target_files) {
        subject.class.stubs(:script_directory).returns(fixture_path)
        subject.class.target_files(fixture_path)
     }
    it { expect(target_files.length).to eq 1 }
    it { expect(target_files.map { |x| File.split(x)[1] } ).to match_array(expected_data) }
  end

end
