# == Define: logstash::input::xmpp
#
#   This input allows you to receive events over XMPP/Jabber.  This plugin
#   can be used for accepting events from humans or applications XMPP, or
#   you can use it for PubSub or general message passing for logstash to
#   logstash.
#
#
# === Parameters
#
# [*add_field*]
#   Add a field to an event
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*charset*]
#   The character encoding used in this input. Examples include "UTF-8"
#   and "cp1252"  This setting is useful if your log files are in Latin-1
#   (aka cp1252) or in another character set other than UTF-8.  This only
#   affects "plain" format logs since json is UTF-8 already.
#   Value can be any of: "ASCII-8BIT", "UTF-8", "US-ASCII", "Big5",
#   "Big5-HKSCS", "Big5-UAO", "CP949", "Emacs-Mule", "EUC-JP", "EUC-KR",
#   "EUC-TW", "GB18030", "GBK", "ISO-8859-1", "ISO-8859-2", "ISO-8859-3",
#   "ISO-8859-4", "ISO-8859-5", "ISO-8859-6", "ISO-8859-7", "ISO-8859-8",
#   "ISO-8859-9", "ISO-8859-10", "ISO-8859-11", "ISO-8859-13",
#   "ISO-8859-14", "ISO-8859-15", "ISO-8859-16", "KOI8-R", "KOI8-U",
#   "Shift_JIS", "UTF-16BE", "UTF-16LE", "UTF-32BE", "UTF-32LE",
#   "Windows-1251", "BINARY", "IBM437", "CP437", "IBM737", "CP737",
#   "IBM775", "CP775", "CP850", "IBM850", "IBM852", "CP852", "IBM855",
#   "CP855", "IBM857", "CP857", "IBM860", "CP860", "IBM861", "CP861",
#   "IBM862", "CP862", "IBM863", "CP863", "IBM864", "CP864", "IBM865",
#   "CP865", "IBM866", "CP866", "IBM869", "CP869", "Windows-1258",
#   "CP1258", "GB1988", "macCentEuro", "macCroatian", "macCyrillic",
#   "macGreek", "macIceland", "macRoman", "macRomania", "macThai",
#   "macTurkish", "macUkraine", "CP950", "Big5-HKSCS:2008", "CP951",
#   "stateless-ISO-2022-JP", "eucJP", "eucJP-ms", "euc-jp-ms", "CP51932",
#   "eucKR", "eucTW", "GB2312", "EUC-CN", "eucCN", "GB12345", "CP936",
#   "ISO-2022-JP", "ISO2022-JP", "ISO-2022-JP-2", "ISO2022-JP2",
#   "CP50220", "CP50221", "ISO8859-1", "Windows-1252", "CP1252",
#   "ISO8859-2", "Windows-1250", "CP1250", "ISO8859-3", "ISO8859-4",
#   "ISO8859-5", "ISO8859-6", "Windows-1256", "CP1256", "ISO8859-7",
#   "Windows-1253", "CP1253", "ISO8859-8", "Windows-1255", "CP1255",
#   "ISO8859-9", "Windows-1254", "CP1254", "ISO8859-10", "ISO8859-11",
#   "TIS-620", "Windows-874", "CP874", "ISO8859-13", "Windows-1257",
#   "CP1257", "ISO8859-14", "ISO8859-15", "ISO8859-16", "CP878",
#   "Windows-31J", "CP932", "csWindows31J", "SJIS", "PCK", "MacJapanese",
#   "MacJapan", "ASCII", "ANSI_X3.4-1968", "646", "UTF-7", "CP65000",
#   "CP65001", "UTF8-MAC", "UTF-8-MAC", "UTF-8-HFS", "UTF-16", "UTF-32",
#   "UCS-2BE", "UCS-4BE", "UCS-4LE", "CP1251", "UTF8-DoCoMo",
#   "SJIS-DoCoMo", "UTF8-KDDI", "SJIS-KDDI", "ISO-2022-JP-KDDI",
#   "stateless-ISO-2022-JP-KDDI", "UTF8-SoftBank", "SJIS-SoftBank",
#   "locale", "external", "filesystem", "internal"
#   Default value: "UTF-8"
#   This variable is optional
#
# [*debug*]
#   Set to true to enable greater debugging in XMPP. Useful for debugging
#   network/authentication erros.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*format*]
#   The format of input data (plain, json, json_event)
#   Value can be any of: "plain", "json", "json_event", "msgpack_event"
#   Default value: None
#   This variable is optional
#
# [*host*]
#   The xmpp server to connect to. This is optional. If you omit this
#   setting, the host on the user/identity is used. (foo.com for
#   user@foo.com)
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*message_format*]
#   If format is "json", an event sprintf string to build what the display
#   @message should be given (defaults to the raw JSON). sprintf format
#   strings look like %{fieldname} or %{@metadata}.  If format is
#   "json_event", ALL fields except for @type are expected to be present.
#   Not receiving all fields will cause unexpected results.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*password*]
#   The xmpp password for the user/identity.
#   Value type is password
#   Default value: None
#   This variable is required
#
# [*rooms*]
#   if muc/multi-user-chat required, give the name of the room that you
#   want to join: room@conference.domain/nick
#   Value type is array
#   Default value: None
#   This variable is optional
#
# [*tags*]
#   Add any number of arbitrary tags to your event.  This can help with
#   processing later.
#   Value type is array
#   Default value: None
#   This variable is optional
#
# [*type*]
#   Label this input with a type. Types are used mainly for filter
#   activation.  If you create an input with type "foobar", then only
#   filters which also have type "foobar" will act on them.  The type is
#   also stored as part of the event itself, so you can also use the type
#   to search for in the web interface.  If you try to set a type on an
#   event that already has one (for example when you send an event from a
#   shipper to an indexer) then a new input will not override the existing
#   type. A type set at the shipper stays with that event for its life
#   even when sent to another LogStash server.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*user*]
#   The user or resource ID, like foo@example.com.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*instances*]
#   Array of instance names to which this define is.
#   Value type is array
#   Default value: [ 'array' ]
#   This variable is optional
#
# === Extra information
#
#  This define is created based on LogStash version 1.1.12
#  Extra information about this input can be found at:
#  http://logstash.net/docs/1.1.12/inputs/xmpp
#
#  Need help? http://logstash.net/docs/1.1.12/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::xmpp (
  $password,
  $user,
  $type,
  $add_field      = '',
  $host           = '',
  $message_format = '',
  $format         = '',
  $rooms          = '',
  $tags           = '',
  $debug          = '',
  $charset        = '',
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::logstash_group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/input_xmpp_${name}")
    $services     = prefix($instances, 'logstash-')
    $filesdir     = "${logstash::configdir}/files/input/xmpp/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_xmpp_${name}"
    $services  = 'logstash'
    $filesdir  = "${logstash::configdir}/files/input/xmpp/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
  }

  if ($rooms != '') {
    validate_array($rooms)
    $arr_rooms = join($rooms, '\', \'')
    $opt_rooms = "  rooms => ['${arr_rooms}']\n"
  }

  if ($debug != '') {
    validate_bool($debug)
    $opt_debug = "  debug => ${debug}\n"
  }

  if ($add_field != '') {
    validate_hash($add_field)
    $var_add_field = $add_field
    $arr_add_field = inline_template('<%= "["+var_add_field.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_add_field = "  add_field => ${arr_add_field}\n"
  }

  if ($charset != '') {
    if ! ($charset in ['ASCII-8BIT', 'UTF-8', 'US-ASCII', 'Big5', 'Big5-HKSCS', 'Big5-UAO', 'CP949', 'Emacs-Mule', 'EUC-JP', 'EUC-KR', 'EUC-TW', 'GB18030', 'GBK', 'ISO-8859-1', 'ISO-8859-2', 'ISO-8859-3', 'ISO-8859-4', 'ISO-8859-5', 'ISO-8859-6', 'ISO-8859-7', 'ISO-8859-8', 'ISO-8859-9', 'ISO-8859-10', 'ISO-8859-11', 'ISO-8859-13', 'ISO-8859-14', 'ISO-8859-15', 'ISO-8859-16', 'KOI8-R', 'KOI8-U', 'Shift_JIS', 'UTF-16BE', 'UTF-16LE', 'UTF-32BE', 'UTF-32LE', 'Windows-1251', 'BINARY', 'IBM437', 'CP437', 'IBM737', 'CP737', 'IBM775', 'CP775', 'CP850', 'IBM850', 'IBM852', 'CP852', 'IBM855', 'CP855', 'IBM857', 'CP857', 'IBM860', 'CP860', 'IBM861', 'CP861', 'IBM862', 'CP862', 'IBM863', 'CP863', 'IBM864', 'CP864', 'IBM865', 'CP865', 'IBM866', 'CP866', 'IBM869', 'CP869', 'Windows-1258', 'CP1258', 'GB1988', 'macCentEuro', 'macCroatian', 'macCyrillic', 'macGreek', 'macIceland', 'macRoman', 'macRomania', 'macThai', 'macTurkish', 'macUkraine', 'CP950', 'Big5-HKSCS:2008', 'CP951', 'stateless-ISO-2022-JP', 'eucJP', 'eucJP-ms', 'euc-jp-ms', 'CP51932', 'eucKR', 'eucTW', 'GB2312', 'EUC-CN', 'eucCN', 'GB12345', 'CP936', 'ISO-2022-JP', 'ISO2022-JP', 'ISO-2022-JP-2', 'ISO2022-JP2', 'CP50220', 'CP50221', 'ISO8859-1', 'Windows-1252', 'CP1252', 'ISO8859-2', 'Windows-1250', 'CP1250', 'ISO8859-3', 'ISO8859-4', 'ISO8859-5', 'ISO8859-6', 'Windows-1256', 'CP1256', 'ISO8859-7', 'Windows-1253', 'CP1253', 'ISO8859-8', 'Windows-1255', 'CP1255', 'ISO8859-9', 'Windows-1254', 'CP1254', 'ISO8859-10', 'ISO8859-11', 'TIS-620', 'Windows-874', 'CP874', 'ISO8859-13', 'Windows-1257', 'CP1257', 'ISO8859-14', 'ISO8859-15', 'ISO8859-16', 'CP878', 'Windows-31J', 'CP932', 'csWindows31J', 'SJIS', 'PCK', 'MacJapanese', 'MacJapan', 'ASCII', 'ANSI_X3.4-1968', '646', 'UTF-7', 'CP65000', 'CP65001', 'UTF8-MAC', 'UTF-8-MAC', 'UTF-8-HFS', 'UTF-16', 'UTF-32', 'UCS-2BE', 'UCS-4BE', 'UCS-4LE', 'CP1251', 'UTF8-DoCoMo', 'SJIS-DoCoMo', 'UTF8-KDDI', 'SJIS-KDDI', 'ISO-2022-JP-KDDI', 'stateless-ISO-2022-JP-KDDI', 'UTF8-SoftBank', 'SJIS-SoftBank', 'locale', 'external', 'filesystem', 'internal']) {
      fail("\"${charset}\" is not a valid charset parameter value")
    } else {
      $opt_charset = "  charset => \"${charset}\"\n"
    }
  }

  if ($format != '') {
    if ! ($format in ['plain', 'json', 'json_event', 'msgpack_event']) {
      fail("\"${format}\" is not a valid format parameter value")
    } else {
      $opt_format = "  format => \"${format}\"\n"
    }
  }

  if ($password != '') {
    validate_string($password)
    $opt_password = "  password => \"${password}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  if ($user != '') {
    validate_string($user)
    $opt_user = "  user => \"${user}\"\n"
  }

  if ($message_format != '') {
    validate_string($message_format)
    $opt_message_format = "  message_format => \"${message_format}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n xmpp {\n${opt_add_field}${opt_charset}${opt_debug}${opt_format}${opt_host}${opt_message_format}${opt_password}${opt_rooms}${opt_tags}${opt_type}${opt_user} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
