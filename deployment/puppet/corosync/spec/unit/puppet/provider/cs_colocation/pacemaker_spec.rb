require 'spec_helper'

describe Puppet::Type.type(:cs_colocation).provider(:pacemaker) do

  let(:resource) { Puppet::Type.type(:cs_colocation).new(
      :name => 'my_colocation',
      :provider => :pacemaker,
      :primitives => %w(foo bar)
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
    it 'should create colocation with corresponding members' do
      resource[:primitives] = %w(p_1 p_2)
      resource[:score] = 'inf'
      provider.expects(:cibadmin_apply_patch).with(<<-eos
<diff>
  <diff-added>
    <cib>
      <configuration>
        <constraints>
          <rsc_colocation id='my_colocation' rsc='p_1' score='INFINITY' with-rsc='p_2'/>
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
    it 'should destroy colocation with corresponding name' do
      provider.expects(:cibadmin_remove).with("<rsc_colocation id='my_colocation'/>")
      provider.destroy
      provider.flush
    end
  end


end

