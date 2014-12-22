require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l2_bridge).provide(:lnx, :parent => Puppet::Provider::Lnx_base) do
  defaultfor :osfamily => :Linux
  commands   :brctl   => 'brctl',
             :iproute => 'ip'

  def exists?
    brctl('show', @resource[:bridge]).split(/\n+/).select{|v| v=~/^#{@resource[:bridge]}\s+\d+/}.size > 0  ?  true  :  false
  end

  def create
    brctl('addbr', @resource[:bridge])
    iproute('link', 'set', 'up', 'dev', @resource[:bridge])
    notice("bridge '#{@resource[:bridge]}' created.")
  end

  def destroy
    iproute('link', 'set', 'down', 'dev', @resource[:bridge])
    brctl('delbr', @resource[:bridge])
  end

end
