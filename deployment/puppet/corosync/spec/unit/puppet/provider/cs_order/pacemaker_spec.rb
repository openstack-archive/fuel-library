require 'spec_helper'

describe Puppet::Type.type(:cs_order).provider(:pacemaker) do

  let(:resource) { Puppet::Type.type(:cs_order).new(
      :name => 'my_order',
      :provider => :pacemaker,
      :first => 'p_1',
      :second => 'p_2'
  ) }
  let(:provider) do
    provider = resource.provider
    #class << provider
    #  def debug(msg)
    #    puts msg
    #  end
    #
    #  def cibadmin_apply_patch(xml)
    #    debug "Apply XML patch:\n#{xml}"
    #  end
    #
    #  def cibadmin_remove(xml)
    #    debug "Remove XML section:\n#{xml}"
    #  end
    #end
    provider.stubs(:cluster_debug_report).returns(true)
    provider
  end

  describe '#create' do
    it 'should create order with corresponding members' do
      resource[:first] = 'p_1'
      resource[:second] ='p_2'
      resource[:score] = 'inf'
      provider.expects(:cibadmin_apply_patch).with(<<-eos
<diff>
  <diff-added>
    <cib>
      <configuration>
        <constraints>
          <rsc_order first='p_1' id='my_order' score='INFINITY' then='p_2'/>
        </constraints>
      </configuration>
    </cib>
  </diff-added>
</diff>
      eos
      )
      provider.create
      provider.flush
    end
  end

  describe '#destroy' do
    it 'should destroy order with corresponding name' do
      provider.expects(:cibadmin_remove).with("<rsc_order id='my_order'/>")
      provider.destroy
      provider.flush
    end
  end

end

