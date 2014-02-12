require 'puppet/util/filetype'
require 'digest/md5'

Puppet::Type.type(:zabbix_configuration_import).provide(:ruby) do
  confine :feature => :zabbixapi

  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../../../../lib/ruby/")
  require 'zabbix'
  require 'pp'

  def exists?
    extend Zabbix
    macroname = '{$TMPL_' + Pathname.new(resource[:xml_file]).basename.to_s.gsub('.', '_').upcase + '}'
    macroid = nil
    result = zbx.query(
      :method => 'usermacro.get',
      :params => {
        'globalmacro' => true,
        'output'      => 'extend'
      }
    )
    result.each { |macro| macroid = macro['globalmacroid'].to_i if macro['macro'] == macroname }
    macroid.is_a? Integer
  end

  def create
    extend Zabbix
    macroname = '{$TMPL_' + Pathname.new(resource[:xml_file]).basename.to_s.gsub('.', '_').upcase + '}'
    xml_file_checksum = config_import(resource[:xml_file])
    zbx.query(
      :method => 'usermacro.createglobal',
      :params => {
          'macro'  => macroname,
          'value'  => xml_file_checksum
      }
    )
  end

  def destroy
    extend Zabbix
    macroname = '{$TMPL_' + Pathname.new(resource[:xml_file]).basename.to_s.gsub('.', '_').upcase + '}'
    macroid = nil
    result = zbx.query(
      :method => 'usermacro.get',
      :params => {
        'globalmacro' => true,
        'output'      => 'extend'
      }
    )
    result.each { |macro| macroid = macro['globalmacroid'].to_i if macro['macro'] == macroname }
    zbx.query(
      :method => 'usermacro.deleteglobal',
      :params => [macroid]
    )
  end

  def xml_file
    extend Zabbix
    macrovalue = nil
    macroname = '{$TMPL_' + Pathname.new(resource[:xml_file]).basename.to_s.gsub('.', '_').upcase + '}'
    result = zbx.query(
      :method => 'usermacro.get',
      :params => {
        'globalmacro' => true,
        'output'      => 'extend'
      }
    )
    result.each { |macro| macrovalue = macro['value'].to_s if macro['macro'] == macroname }
    macrovalue
  end

  def xml_file=(v)
    extend Zabbix
    macroid = nil
    xml_file_checksum = config_import(resource[:xml_file])
    macroname = '{$TMPL_' + Pathname.new(resource[:xml_file]).basename.to_s.gsub('.', '_').upcase + '}'
    result = zbx.query(
      :method => 'usermacro.get',
      :params => {
        'globalmacro' => true,
        'output'      => 'extend'
      }
    )
    result.each { |macro| macroid = macro['globalmacroid'].to_i if macro['macro'] == macroname }
    zbx.query(
      :method => 'usermacro.updateglobal',
      :params => {
        'globalmacroid' => macroid,
        'value'         => xml_file_checksum
      }
    )
  end

  def config_import(xml_file)
    xml_file_content = Puppet::Util::FileType.filetype(:flat).new(xml_file).read
    xml_file_checksum = Digest::MD5.hexdigest(xml_file_content)
    zbx.query(
      :method => 'configuration.import',
      :params => {
        'format' => 'xml',
        'source' => xml_file_content,
        'rules'  => {
          'applications' => {
            'createMissing' => true, 'updateExisting' => true
          },
          'discoveryRules' => {
            'createMissing' => true, 'updateExisting' => true
          },
          'graphs' => {
            'createMissing' => true, 'updateExisting' => true
          },
          'groups' => {
            'createMissing' => true, 'updateExisting' => true
          },
          'images' => {
            'createMissing' => true, 'updateExisting' => true
          },
          'items' => {
            'createMissing' => true, 'updateExisting' => true
          },
          'maps' => {
            'createMissing' => true, 'updateExisting' => true
          },
          'screens' => {
            'createMissing' => true, 'updateExisting' => true
          },
          'templates' => {
            'createMissing' => true, 'updateExisting' => true
          },
          'templateScreens' => {
            'createMissing' => true, 'updateExisting' => true
          },
          'triggers' => {
            'createMissing' => true, 'updateExisting' => true
          }
        }
      }
    )
    xml_file_checksum
  end

end
