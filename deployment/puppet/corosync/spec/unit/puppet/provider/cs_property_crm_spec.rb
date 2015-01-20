require 'spec_helper'

describe Puppet::Type.type(:cs_property).provider(:crm) do
  before do
    described_class.stubs(:command).with(:crm).returns 'crm'
  end

  context 'when getting instances' do
    let :instances do

      test_cib = <<-EOS
        <cib>
          <configuration>
            <crm_config>
              <cluster_property_set>
                <nvpair name="apples" value="red"/>
                <nvpair name="oranges" value="orange"/>
              </cluster_property_set>
            </crm_config>
          </configuration>
        </cib>
      EOS

      described_class.expects(:block_until_ready).returns(nil)
      if Puppet::PUPPETVERSION.to_f < 3.4
        Puppet::Util::SUIDManager.expects(:run_and_capture).with(['crm', 'configure', 'show', 'xml']).at_least_once.returns([test_cib, 0])
      else
        Puppet::Util::Execution.expects(:execute).with(['crm', 'configure', 'show', 'xml']).at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new(test_cib, 0)
        )
      end
      instances = described_class.instances
    end

    it 'should have an instance for each <nvpair> in <cluster_property_set>' do
      expect(instances.count).to eq(2)
    end

    describe 'each instance' do
      let :instance do
        instances.first
      end

      it "is a kind of #{described_class.name}" do
        expect(instance).to be_a_kind_of(described_class)
      end

      it "is named by the <nvpair>'s name attribute" do
        expect(instance.name).to eq("apples")
      end

      it "has a value corresponding to the <nvpair>'s value attribute" do
        expect(instance.value).to eq("red")
      end
    end
  end
end
