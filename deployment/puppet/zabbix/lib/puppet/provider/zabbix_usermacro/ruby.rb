Puppet::Type.type(:zabbix_usermacro).provide(:ruby) do
  confine :feature => :zabbixapi

  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../../../../lib/ruby/")
  require "zabbix"
  require "pp"

  def exists?
    extend Zabbix
    macroid = nil
    if resource[:global] == :true
      result = zbx.query(
        :method => 'usermacro.get',
        :params => {
          "globalmacro" => true,
          "output"      => "extend"
        }
      )
      result.each { |macro| macroid = macro['globalmacroid'].to_i if macro['macro'] == resource[:macro] }
    else
      result = zbx.query(
        :method => 'usermacro.get',
        :params => {
          "hostids" => get_id(resource[:host], 0),
          "output"  => "extend"
        }
      )
      macroid = nil
      result.each { |macro| macroid = macro['hostmacroid'].to_i if macro['macro'] == resource[:macro] }
    end
    macroid.is_a? Integer
  end
  
  def create
    extend Zabbix
    if resource[:global] == :true
      zbx.query(
        :method => 'usermacro.createglobal',
        :params => {
            'macro'  => resource[:macro],
            'value'  => resource[:value]      }
      )
    else
      zbx.query(
        :method => 'usermacro.create',
        :params => {
            'macro'  => resource[:macro],
            'value'  => resource[:value],
            "hostid" => get_id(resource[:host], 0)
        }
      )
    end
  end

  def destroy
    extend Zabbix
    macroid = nil
    if resource[:global] == :true
      result = zbx.query(
        :method => 'usermacro.get',
        :params => {
          "globalmacro" => true,
          "output"      => "extend"
        }
      )
      result.each { |macro| macroid = macro['globalmacroid'].to_i if macro['macro'] == resource[:macro] }
      zbx.query(
        :method => 'usermacro.deleteglobal',
        :params => [macroid]
      )
    else
      result = zbx.query(
        :method => 'usermacro.get',
        :params => {
          "hostids"     => get_id(resource[:host], 0),
          "output"      => "extend"
        }
      )
      result.each { |macro| macroid = macro['hostmacroid'].to_i if macro['macro'] == resource[:macro] }
      zbx.query(
        :method => 'usermacro.delete',
        :params => [macroid]
      )
    end
  end

  def value
    #get value
    extend Zabbix
    macrovalue = nil
    if resource[:global] == :true
      result = zbx.query(
        :method => 'usermacro.get',
        :params => {
          "globalmacro" => true,
          "output"      => "extend"
        }
      )
      result.each { |macro| macrovalue = macro['value'].to_s if macro['macro'] == resource[:macro] }
    else
      result = zbx.query(
        :method => 'usermacro.get',
        :params => {
          "hostids"     => get_id(resource[:host], 0),
          "output"      => "extend"
        }
      )
      result.each { |macro| macrovalue = macro['value'].to_s if macro['macro'] == resource[:macro] }
    end
    macrovalue
  end

  def value=(v)
    #set value (to v?)
    extend Zabbix
    macroid = nil
    if resource[:global] == :true
      result = zbx.query(
        :method => 'usermacro.get',
        :params => {
          "globalmacro" => true,
          "output"      => "extend"
        }
      )
      result.each { |macro| macroid = macro['globalmacroid'].to_i if macro['macro'] == resource[:macro] }
      zbx.query(
        :method => 'usermacro.updateglobal',
        :params => {
          'globalmacroid' => macroid,
          'value'         => resource[:value]
        }
      )
    else
      result = zbx.query(
        :method => 'usermacro.get',
        :params => {
          "hostids"     => get_id(resource[:host], 0),
          "output"      => "extend"
        }
      )
      result.each { |macro| macroid = macro['hostmacroid'].to_i if macro['macro'] == resource[:macro] }
      zbx.query(
        :method => 'usermacro.update',
        :params => {
          'hostmacroid' => macroid,
          'value'       => resource[:value]
        }
      )
    end
  end

end
