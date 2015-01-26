require 'spec_helper'

describe Puppet::Type.type(:cs_primitive).provider(:crm) do
  before do
    described_class.stubs(:command).with(:crm).returns 'crm'
  end

  context 'when getting instances' do
    let :instances do

      test_cib = <<-EOS
        <configuration>
          <resources>
            <primitive class="ocf" id="example_vm" provider="heartbeat" type="Xen">
              <instance_attributes id="example_vm-instance_attributes">
                <nvpair id="example_vm-instance_attributes-xmfile" name="xmfile" value="/etc/xen/example_vm.cfg"/>
                <nvpair id="example_vm-instance_attributes-name" name="name" value="example_vm_name"/>
              </instance_attributes>
              <utilization id="example_vm-utilization">
                <nvpair id="example_vm-utilization-ram" name="ram" value="256"/>
              </utilization>
              <meta_attributes id="example_vm-meta_attributes">
                <nvpair id="example_vm-meta_attributes-target-role" name="target-role" value="Started"/>
                <nvpair id="example_vm-meta_attributes-priority" name="priority" value="7"/>
              </meta_attributes>
              <operations>
                <op id="example_vm-start-0" interval="0" name="start" timeout="60"/>
                <op id="example_vm-stop-0" interval="0" name="stop" timeout="40"/>
                <op id="nginx-monitor-15s" interval="15" name="monitor" on-fail="standby" timeout="10">
                  <instance_attributes id="nginx-monitor-15s-instance_attributes">
                    <nvpair id="nginx-monitor-15s-instance_attributes-OCF_CHECK_LEVEL" name="OCF_CHECK_LEVEL" value="10"/>
                  </instance_attributes>
                </op>
                <op id="nginx-monitor-5s" interval="5" name="monitor" on-fail="standby" timeout="10" role="Master"/>
              </operations>
            </primitive>
          </resources>
        </configuration>
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

    it 'should have an instance for each <primitive>' do
      expect(instances.count).to eq(1)
    end

    describe 'each instance' do
      let :instance do
        instances.first
      end

      it "is a kind of #{described_class.name}" do
        expect(instance).to be_a_kind_of(described_class)
      end

      it "is named by the <primitive>'s id attribute" do
        expect(instance.name).to eq(:example_vm)
      end

      it "has an primitive_class parameter corresponding to the <primitive>'s class attribute" do
        pending 'knowing the proper way to assert this'
        expect(instance.primitive_class).to eq("ocf")
      end

      it "has an primitive_type parameter corresponding to the <primitive>'s type attribute" do
        pending 'knowing the proper way to assert this'
        expect(instance.primitive_type).to eq("Xen")
      end

      it "has an provided_by parameter corresponding to the <primitive>'s provider attribute" do
        pending 'knowing the proper way to assert this'
        expect(instance.provided_by).to eq("heartbeat")
      end

      it 'has a parameters property corresponding to <instance_attributes>' do
        expect(instance.parameters).to eq({
          "xmfile" => "/etc/xen/example_vm.cfg",
          "name" => "example_vm_name",
        })
      end

      it 'has an operations property corresponding to <operations>' do
        expect(instance.operations).to eq({
          "monitor" => [
            {"interval" => "15", "timeout" => "10", "on-fail" => "standby", "OCF_CHECK_LEVEL" => "10"},
            {"interval" => "5", "timeout" => "10", "on-fail" => "standby", "role" => "Master"}
          ],
          "start" => {"interval" => "0", "timeout" => "60"},
          "stop" => {"interval" => "0", "timeout" => "40"},
        })
      end

      it 'has a utilization property corresponding to <utilization>' do
        expect(instance.utilization).to eq({
          "ram" => "256",
        })
      end

      it 'has a metadata property corresponding to <meta_attributes>' do
        expect(instance.metadata).to eq({
          "target-role" => "Started",
          "priority" => "7",
        })
      end

      it 'has an ms_metadata property' do
        expect(instance).to respond_to(:ms_metadata)
      end

      it "has a promotable property that is :false" do
        expect(instance.promotable).to eq(:false)
      end
    end
  end

  context 'when flushing' do
    let :resource do
      Puppet::Type.type(:cs_primitive).new(
        :name => 'testResource',
        :provider => :crm,
        :primitive_class => 'ocf',
        :provided_by => 'heartbeat',
        :primitive_type => 'IPaddr2')
    end

    let :instance do
      instance = described_class.new(resource)
      instance.create
      instance
    end

    def expect_update(pattern)
      instance.expects(:crm).with { |*args|
        if args.slice(0..2) == ['configure', 'load', 'update']
          expect(File.read(args[3])).to match(pattern)
          true
        else
          false
        end
      }
    end

    it 'can flush without changes' do
      expect_update(//)
      instance.flush
    end

    it 'sets operations' do
      instance.operations = {'monitor' => {'interval' => '10s'}}
      expect_update(/op monitor interval=10s/)
      instance.flush
    end

    it 'sets utilization' do
      instance.utilization = {'waffles' => '5'}
      expect_update(/utilization waffles=5/)
      instance.flush
    end

    it 'sets parameters' do
      instance.parameters = {'fluffyness' => '12'}
      expect_update(/params 'fluffyness=12'/)
      instance.flush
    end

    it 'sets metadata' do
      instance.metadata = {'target-role' => 'Started'}
      expect_update(/meta target-role=Started/)
      instance.flush
    end

    it 'sets the primitive name and type' do
      expect_update(/primitive testResource ocf:heartbeat:IPaddr2/)
      instance.flush
    end
  end
end
