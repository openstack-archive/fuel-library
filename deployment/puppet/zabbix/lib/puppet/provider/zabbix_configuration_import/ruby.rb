$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/provider/zabbix'
require 'digest/md5'

Puppet::Type.type(:zabbix_configuration_import).provide(:ruby,
                                                        :parent => Puppet::Provider::Zabbix) do

  def exists?
    auth(resource[:api])
    macroname = '{$TMPL_' + Pathname.new(resource[:xml_file]).basename.to_s.gsub('.', '_').upcase + '}'
    macroid = nil
    result = api_request(resource[:api],
                         {:method => 'usermacro.get',
                          :params => {:globalmacro => true,
                                      :output      => 'extend'}})
    result.each { |macro| macroid = macro['globalmacroid'] if macro['macro'] == macroname }
    not macroid.nil?
  end

  def create
    macroname = '{$TMPL_' + Pathname.new(resource[:xml_file]).basename.to_s.gsub('.', '_').upcase + '}'
    xml_file_checksum = config_import(resource[:xml_file])
    api_request(resource[:api],
                {:method => 'usermacro.createglobal',
                 :params => {:macro => macroname,
                             :value => xml_file_checksum}})
  end

  def destroy
    macroname = '{$TMPL_' + Pathname.new(resource[:xml_file]).basename.to_s.gsub('.', '_').upcase + '}'
    macroid = nil
    result = api_request(resource[:api],
                         {:method => 'usermacro.get',
                          :params => {:globalmacro => true,
                                      :output      => 'extend'}})
    result.each { |macro| macroid = macro['globalmacroid'] if macro['macro'] == macroname }
    api_request(resource[:api],
                {:method => 'usermacro.deleteglobal',
                 :params => [macroid]})
  end

  def xml_file
    macrovalue = nil
    macroname = '{$TMPL_' + Pathname.new(resource[:xml_file]).basename.to_s.gsub('.', '_').upcase + '}'
    result = api_request(resource[:api],
                         {:method => 'usermacro.get',
                          :params => {:globalmacro => true,
                                      :output      => 'extend'}})
    result.each { |macro| macrovalue = macro['value'] if macro['macro'] == macroname }
    macrovalue
  end

  def xml_file=(v)
    macroid = nil
    xml_file_checksum = config_import(resource[:xml_file])
    macroname = '{$TMPL_' + Pathname.new(resource[:xml_file]).basename.to_s.gsub('.', '_').upcase + '}'
    result = api_request(resource[:api],
                         {:method => 'usermacro.get',
                          :params => {:globalmacro => true,
                                      :output      => 'extend'}})
    result.each { |macro| macroid = macro['globalmacroid'] if macro['macro'] == macroname }
    api_request(resource[:api],
                {:method => 'usermacro.updateglobal',
                 :params => {:globalmacroid => macroid,
                             :value         => xml_file_checksum}})
  end

  def config_import(xml_file)
    xml_file_content = Puppet::Util::FileType.filetype(:flat).new(xml_file).read
    xml_file_checksum = Digest::MD5.hexdigest(xml_file_content)
    api_request(resource[:api],
                {:method => 'configuration.import',
                 :params => {:format => 'xml',
                             :source => xml_file_content,
                             :rules  => {:applications    => {:createMissing  => true,
                                                              :updateExisting => true},
                                         :discoveryRules  => {:createMissing  => true,
                                                              :updateExisting => true},
                                         :graphs          => {:createMissing  => true,
                                                              :updateExisting => true},
                                         :groups          => {:createMissing  => true,
                                                              :updateExisting => true},
                                         :images          => {:createMissing  => true,
                                                              :updateExisting => true},
                                         :items           => {:createMissing  => true,
                                                              :updateExisting => true},
                                         :maps            => {:createMissing  => true,
                                                              :updateExisting => true},
                                         :screens         => {:createMissing  => true,
                                                              :updateExisting => true},
                                         :templates       => {:createMissing  => true,
                                                             :updateExisting  => true},
                                         :templateScreens => {:createMissing  => true,
                                                              :updateExisting => true},
                                         :triggers        => {:createMissing  => true,
                                                              :updateExisting => true}}}})
    xml_file_checksum
  end

end
