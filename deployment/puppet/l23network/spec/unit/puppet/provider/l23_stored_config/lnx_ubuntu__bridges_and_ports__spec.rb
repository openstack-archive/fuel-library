require 'spec_helper'

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_ubuntu) do

  let(:input_data) do
    {
      :eth1 => {
                 :name     => "eth1",
                 :provider => "lnx_ubuntu",
                 :if_type  => "ethernet",
                 :bridge   => "br-storage",
               },
      :'br-storage' => {
                 :name     => "br-storage",
                 :onboot   => "yes",
                 :if_type  => "bridge",
                 :ipaddr   => "192.168.88.6/24",
                 :provider => "lnx_ubuntu",
               }
    }
  end

  let(:resources) do
    resources = {}
    input_data.each do |name, res|
      resources.store name, Puppet::Type.type(:l23_stored_config).new(res)
    end
    resources
  end

  let(:providers) do
    providers = {}
    resources.each do |name, resource|
      provider = resource.provider
      if ENV['SPEC_PUPPET_DEBUG']
        class << provider
          def debug(msg)
            puts msg
          end
        end
      end
      provider.create
      providers.store name, provider
    end
    providers
  end

  context "when formatting resources" do

    context 'with test interface eth1' do
      subject { providers[:eth1] }
      let(:data) { subject.class.format_file('filepath', [subject]) }

      it { expect(data).to match %r(auto eth1) }
      it { expect(data).to match %r(iface eth1 inet manual) }
      it { expect(data).not_to match %r(.*ethernet.*) }
    end

    context 'with test interface br-storage' do
      subject { providers[:'br-storage'] }
      let(:data) { subject.class.format_file('filepath', [subject]) }
      let(:catalog) {
        catalog = stub('catalog', nil)
        catalog.stubs(:resources).returns resources.values
        catalog.stubs(:resource).with('L3_stored_config', 'eth1').returns(resources[:eth1])
        catalog.stubs(:resource).with('L3_stored_config', 'br-storage').returns(resources[:'br-storage'])
        catalog
      }

      before(:each) do
        subject.resource.stubs(:catalog).returns(catalog)
      end

#      it {
#      require 'pry'
#      binding.pry
#      }
       it { expect(data).to match %r(auto br-storage) }
       it { expect(data).to match %r(iface br-storage inet manual) }
       it { expect(data).to match %r(address 192.168.88.6/24) }
#      it { expect(data).to match %r(bridge_ports eth1) } ##l23_stored_config does not populate bridge_ports
    end

  end

end
