require 'spec_helper'
require 'puppet/provider/crmsh'

describe Puppet::Provider::Crmsh do
  let :provider do
    described_class.new
  end

  it 'declares a crm_attribute command' do
    expect{
      described_class.command :crm_attribute
    }.not_to raise_error
  end

  describe '#ready' do
    before do
      # this would probably return nil on the test platform, unless
      # crm_attribute happens to be installed.
      described_class.stubs(:command).with(:crm_attribute).returns 'crm_attribute'
    end

    it 'returns true when crm_attribute exits successfully' do
      if Puppet::PUPPETVERSION.to_f < 3.4
        Puppet::Util::SUIDManager.expects(:run_and_capture).with(['crm_attribute', '--type', 'crm_config', '--query', '--name', 'dc-version']).returns(['', 0])
      else
        Puppet::Util::Execution.expects(:execute).with(['crm_attribute', '--type', 'crm_config', '--query', '--name', 'dc-version'],{:failonfail => false}).returns(
          Puppet::Util::Execution::ProcessOutput.new('', 0)
        )
      end

      expect(described_class.ready?).to be_truthy
    end

    it 'returns false when crm_attribute exits unsuccessfully' do
      if Puppet::PUPPETVERSION.to_f < 3.4
        Puppet::Util::SUIDManager.expects(:run_and_capture).with(['crm_attribute', '--type', 'crm_config', '--query', '--name', 'dc-version']).returns(['', 1])
      else
        Puppet::Util::Execution.expects(:execute).with(['crm_attribute', '--type', 'crm_config', '--query', '--name', 'dc-version'],{:failonfail => false}).returns(
          Puppet::Util::Execution::ProcessOutput.new('', 1)
        )
      end

      expect(described_class.ready?).to be_falsey
    end
  end
end
