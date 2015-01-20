require 'spec_helper'

describe Puppet::Type.type(:cs_primitive).provider(:pcs) do
  before do
    described_class.stubs(:command).with(:pcs).returns 'pcs'
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
              </operations>
            </primitive>
          </resources>
        </configuration>
      EOS

      described_class.expects(:block_until_ready).returns(nil)
      if Puppet::PUPPETVERSION.to_f < 3.4
        Puppet::Util::SUIDManager.expects(:run_and_capture).with(['pcs', 'cluster', 'cib']).at_least_once.returns([test_cib, 0])
      else
        Puppet::Util::Execution.expects(:execute).with(['pcs', 'cluster', 'cib'], {:failonfail => true}).at_least_once.returns(
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

      it 'has a parameters property corresponding to <instance_attributes>' do
        expect(instance.parameters).to eq({
          "xmfile" => "/etc/xen/example_vm.cfg",
          "name" => "example_vm_name",
        })
      end

      it 'has an operations property corresponding to <operations>' do
        expect(instance.operations).to eq({
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

    let :instances do

      test_cib = <<-EOS
        <configuration>
          <resources>
            <primitive class="ocf" id="example_vip" provider="heartbeat" type="IPaddr2">
              <operations>
                <op id="example_vip-monitor-10s" interval="10s" name="monitor"/>
              </operations>
              <instance_attributes id="example_vip-instance_attributes">
                <nvpair id="example_vip-instance_attributes-cidr_netmask" name="cidr_netmask" value="24"/>
                <nvpair id="example_vip-instance_attributes-ip" name="ip" value="172.31.110.68"/>
              </instance_attributes>
            </primitive>
          </resources>
        </configuration>
      EOS

      described_class.expects(:block_until_ready).returns(nil)
      if Puppet::PUPPETVERSION.to_f < 3.4
        Puppet::Util::SUIDManager.expects(:run_and_capture).with(['pcs', 'cluster', 'cib']).at_least_once.returns([test_cib, 0])
      else
        Puppet::Util::Execution.expects(:execute).with(['pcs', 'cluster', 'cib'], {:failonfail => true}).at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new(test_cib, 0)
        )
      end
      instances = described_class.instances
    end

    def expect_update(pattern)
      if Puppet::PUPPETVERSION.to_f < 3.4
        Puppet::Util::SUIDManager.expects(:run_and_capture).with { |*args|
          cmdline=args[0].join(" ")
          expect(cmdline).to match(pattern)
          true
        }.at_least_once.returns(['', 0])
      else
        Puppet::Util::Execution.expects(:execute).with{ |*args|
          cmdline=args[0].join(" ")
          expect(cmdline).to match(pattern)
          true
        }.at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new('', 0)
        )
      end
    end

    let :prefetch do
      described_class.prefetch
    end

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

    let :vip_instance do
      vip_instance = instances.first
      vip_instance
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
      expect_update(/(pcs resource op remove|utilization waffles=5)/)
      instance.flush
    end

    it 'sets parameters' do
      instance.parameters = {'fluffyness' => '12'}
      expect_update(/(pcs resource op remove|fluffyness=12)/)
      instance.flush
    end

    it 'sets metadata' do
      instance.metadata = {'target-role' => 'Started'}
      expect_update(/(pcs resource op remove|meta target-role=Started)/)
      instance.flush
    end

    it 'sets the primitive name and type' do
      expect_update(/^pcs resource (create testResource ocf:heartbeat:IPaddr2|op remove testResource monitor interval=60s)/)
      instance.flush
    end

    it "sets a primitive_class parameter corresponding to the <primitive>'s class attribute" do
      vip_instance.primitive_class = 'IPaddr3'
      expect_update(/resource (create|delete|op remove) example_vip/)
      vip_instance.flush
    end

    it "sets an primitive_type parameter corresponding to the <primitive>'s type attribute" do
      vip_instance.primitive_type = 'stonith'
      expect_update(/resource (create|delete|op remove) example_vip/)
      vip_instance.flush
    end

    it "sets an provided_by parameter corresponding to the <primitive>'s provider attribute" do
      vip_instance.provided_by = 'inuits'
      expect_update(/resource (create|delete|op remove) example_vip/)
      vip_instance.flush
    end

  end
end
