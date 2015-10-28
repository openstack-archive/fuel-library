  it do
    expect(subject).to contain_class('Osnailyfacter::Apache').with(
      :name             => "Osnailyfacter::Apache",
      :listen_ports     => ["80", "8888", "5000", "35357"],
      :purge_configs    => false,
      :logrotate_rotate => "52",
    )
  end

  it do
    expect(subject).to contain_class('Apache::Version').with(
      :name => "Apache::Version",
    )
  end

  it do
    expect(subject).to contain_class('Apache::Params').with(
      :name => "Apache::Params",
    )
  end

  it do
    expect(subject).to contain_class('Apache').with(
      :name                   => "Apache",
      :mpm_module             => false,
      :default_vhost          => false,
      :purge_configs          => false,
      :servername             => "node-137",
      :server_tokens          => "Prod",
      :server_signature       => "Off",
      :trace_enable           => "Off",
      :apache_name            => "apache2",
      :service_name           => "apache2",
      :default_mods           => true,
      :default_confd_files    => true,
      :default_ssl_vhost      => false,
      :default_ssl_cert       => "/etc/ssl/certs/ssl-cert-snakeoil.pem",
      :default_ssl_key        => "/etc/ssl/private/ssl-cert-snakeoil.key",
      :default_type           => "none",
      :service_enable         => true,
      :service_manage         => true,
      :service_ensure         => "running",
      :purge_vdir             => false,
      :serveradmin            => "root@localhost",
      :sendfile               => "On",
      :error_documents        => false,
      :timeout                => "120",
      :httpd_dir              => "/etc/apache2",
      :server_root            => "/etc/apache2",
      :conf_dir               => "/etc/apache2",
      :confd_dir              => "/etc/apache2/conf.d",
      :vhost_dir              => "/etc/apache2/sites-available",
      :vhost_enable_dir       => "/etc/apache2/sites-enabled",
      :mod_dir                => "/etc/apache2/mods-available",
      :mod_enable_dir         => "/etc/apache2/mods-enabled",
      :lib_path               => "/usr/lib/apache2/modules",
      :conf_template          => "apache/httpd.conf.erb",
      :manage_user            => true,
      :manage_group           => true,
      :user                   => "www-data",
      :group                  => "www-data",
      :keepalive              => "Off",
      :keepalive_timeout      => "15",
      :max_keepalive_requests => "100",
      :logroot                => "/var/log/apache2",
      :log_level              => "warn",
      :log_formats            => {},
      :ports_file             => "/etc/apache2/ports.conf",
      :docroot                => "/var/www",
      :apache_version         => "2.4",
      :package_ensure         => "installed",
      :use_optional_includes  => false,
    )
  end

  it do
    expect(subject).to contain_package('httpd').with(
      :name   => "apache2",
      :ensure => "installed",
      :notify => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_user('www-data').with(
      :name    => "www-data",
      :ensure  => "present",
      :gid     => "www-data",
      :require => Package[httpd]{:name=>"httpd"},
    )
  end

  it do
    expect(subject).to contain_group('www-data').with(
      :name    => "www-data",
      :ensure  => "present",
      :require => Package[httpd]{:name=>"httpd"},
    )
  end

  it do
    expect(subject).to contain_class('Apache::Service').with(
      :name           => "Apache::Service",
      :service_name   => "apache2",
      :service_enable => true,
      :service_manage => true,
      :service_ensure => "running",
    )
  end

  it do
    expect(subject).to contain_service('httpd').with(
      :name       => "apache2",
      :ensure     => "running",
      :enable     => true,
      :restart    => "sleep 30 && apachectl graceful || apachectl restart",
      :hasrestart => true,
    )
  end

  it do
    expect(subject).to contain_exec('mkdir /etc/apache2/conf.d').with(
      :command => "mkdir /etc/apache2/conf.d",
      :creates => "/etc/apache2/conf.d",
      :require => Package[httpd]{:name=>"httpd"},
      :path    => "/bin:/sbin:/usr/bin:/usr/sbin",
    )
  end

  it do
    expect(subject).to contain_file('/etc/apache2/conf.d').with(
      :path    => "/etc/apache2/conf.d",
      :ensure  => "directory",
      :recurse => true,
      :purge   => false,
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
      :require => Package[httpd]{:name=>"httpd"},
    )
  end

  it do
    expect(subject).to contain_exec('mkdir /etc/apache2/mods-available').with(
      :command => "mkdir /etc/apache2/mods-available",
      :creates => "/etc/apache2/mods-available",
      :require => Package[httpd]{:name=>"httpd"},
      :path    => "/bin:/sbin:/usr/bin:/usr/sbin",
    )
  end

  it do
    expect(subject).to contain_file('/etc/apache2/mods-available').with(
      :path    => "/etc/apache2/mods-available",
      :ensure  => "directory",
      :recurse => true,
      :purge   => false,
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
      :require => Package[httpd]{:name=>"httpd"},
    )
  end

  it do
    expect(subject).to contain_exec('mkdir /etc/apache2/mods-enabled').with(
      :command => "mkdir /etc/apache2/mods-enabled",
      :creates => "/etc/apache2/mods-enabled",
      :require => Package[httpd]{:name=>"httpd"},
      :path    => "/bin:/sbin:/usr/bin:/usr/sbin",
    )
  end

  it do
    expect(subject).to contain_file('/etc/apache2/mods-enabled').with(
      :path    => "/etc/apache2/mods-enabled",
      :ensure  => "directory",
      :recurse => true,
      :purge   => false,
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
      :require => Package[httpd]{:name=>"httpd"},
    )
  end

  it do
    expect(subject).to contain_exec('mkdir /etc/apache2/sites-available').with(
      :command => "mkdir /etc/apache2/sites-available",
      :creates => "/etc/apache2/sites-available",
      :require => Package[httpd]{:name=>"httpd"},
      :path    => "/bin:/sbin:/usr/bin:/usr/sbin",
    )
  end

  it do
    expect(subject).to contain_file('/etc/apache2/sites-available').with(
      :path    => "/etc/apache2/sites-available",
      :ensure  => "directory",
      :recurse => true,
      :purge   => false,
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
      :require => Package[httpd]{:name=>"httpd"},
    )
  end

  it do
    expect(subject).to contain_exec('mkdir /etc/apache2/sites-enabled').with(
      :command => "mkdir /etc/apache2/sites-enabled",
      :creates => "/etc/apache2/sites-enabled",
      :require => Package[httpd]{:name=>"httpd"},
      :path    => "/bin:/sbin:/usr/bin:/usr/sbin",
    )
  end

  it do
    expect(subject).to contain_file('/etc/apache2/sites-enabled').with(
      :path    => "/etc/apache2/sites-enabled",
      :ensure  => "directory",
      :recurse => true,
      :purge   => false,
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
      :require => Package[httpd]{:name=>"httpd"},
    )
  end

  it do
    expect(subject).to contain_concat('/etc/apache2/ports.conf').with(
      :name           => "/etc/apache2/ports.conf",
      :owner          => "root",
      :group          => "root",
      :mode           => "0644",
      :notify         => Class[Apache::Service]{:name=>"Apache::Service"},
      :require        => Package[httpd]{:name=>"httpd"},
      :ensure         => "present",
      :path           => "/etc/apache2/ports.conf",
      :warn           => false,
      :force          => false,
      :backup         => "puppet",
      :replace        => true,
      :order          => "alpha",
      :ensure_newline => false,
    )
  end

  it do
    expect(subject).to contain_concat__fragment('Apache ports header').with(
      :name    => "Apache ports header",
      :ensure  => "present",
      :target  => "/etc/apache2/ports.conf",
      :content => "# ************************************\n# Listen & NameVirtualHost resources in module puppetlabs-apache\n# Managed by Puppet\n# ************************************\n\n",
      :order   => "10",
    )
  end

  it do
    expect(subject).to contain_file('/etc/apache2/apache2.conf').with(
      :path    => "/etc/apache2/apache2.conf",
      :ensure  => "file",
      :content => "# Security\nServerTokens Prod\nServerSignature Off\nTraceEnable Off\n\nServerName \"node-137\"\nServerRoot \"/etc/apache2\"\nPidFile ${APACHE_PID_FILE}\nTimeout 120\nKeepAlive Off\nMaxKeepAliveRequests 100\nKeepAliveTimeout 15\n\nUser www-data\nGroup www-data\n\nAccessFileName .htaccess\n<FilesMatch \"^\\.ht\">\n    Require all denied\n</FilesMatch>\n\n<Directory />\n  Options FollowSymLinks\n  AllowOverride None\n</Directory>\n\n\nHostnameLookups Off\nErrorLog \"/var/log/apache2/error.log\"\nLogLevel warn\nEnableSendfile On\n\n#Listen 80\n\n\nInclude \"/etc/apache2/mods-enabled/*.load\"\nInclude \"/etc/apache2/mods-enabled/*.conf\"\nInclude \"/etc/apache2/ports.conf\"\n\nLogFormat \"%h %l %u %t \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\"\" combined\nLogFormat \"%h %l %u %t \\\"%r\\\" %>s %b\" common\nLogFormat \"%{Referer}i -> %U\" referer\nLogFormat \"%{User-agent}i\" agent\n\nIncludeOptional \"/etc/apache2/conf.d/*.conf\"\nIncludeOptional \"/etc/apache2/sites-enabled/*\"\n\n",
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
      :require => Package[httpd]{:name=>"httpd"},
    )
  end

  it do
    expect(subject).to contain_class('Apache::Default_mods').with(
      :name           => "Apache::Default_mods",
      :all            => true,
      :apache_version => "2.4",
    )
  end

  it do
    expect(subject).to contain_apache__mod('authz_host').with(
      :name           => "authz_host",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Authn_core').with(
      :name           => "Apache::Mod::Authn_core",
      :apache_version => "2.4",
    )
  end

  it do
    expect(subject).to contain_apache__mod('authn_core').with(
      :name           => "authn_core",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Reqtimeout').with(
      :name     => "Apache::Mod::Reqtimeout",
      :timeouts => ["header=20-40,minrate=500", "body=10,minrate=500"],
    )
  end

  it do
    expect(subject).to contain_apache__mod('reqtimeout').with(
      :name           => "reqtimeout",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_file('reqtimeout.conf').with(
      :path    => "/etc/apache2/mods-available/reqtimeout.conf",
      :ensure  => "file",
      :content => "RequestReadTimeout header=20-40,minrate=500\nRequestReadTimeout body=10,minrate=500\n",
      :require => Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"},
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Alias').with(
      :name           => "Apache::Mod::Alias",
      :apache_version => "2.4",
      :icons_options  => "Indexes MultiViews",
    )
  end

  it do
    expect(subject).to contain_apache__mod('alias').with(
      :name           => "alias",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_file('alias.conf').with(
      :path    => "/etc/apache2/mods-available/alias.conf",
      :ensure  => "file",
      :content => "<IfModule alias_module>\nAlias /icons/ \"/usr/share/apache2/icons/\"\n<Directory \"/usr/share/apache2/icons\">\n    Options Indexes MultiViews\n    AllowOverride None\n    Require all granted\n</Directory>\n</IfModule>\n",
      :require => Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"},
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Authn_file').with(
      :name => "Apache::Mod::Authn_file",
    )
  end

  it do
    expect(subject).to contain_apache__mod('authn_file').with(
      :name           => "authn_file",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Autoindex').with(
      :name => "Apache::Mod::Autoindex",
    )
  end

  it do
    expect(subject).to contain_apache__mod('autoindex').with(
      :name           => "autoindex",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_file('autoindex.conf').with(
      :path    => "/etc/apache2/mods-available/autoindex.conf",
      :ensure  => "file",
      :content => "IndexOptions FancyIndexing VersionSort HTMLTable NameWidth=* DescriptionWidth=* Charset=UTF-8\nAddIconByEncoding (CMP,/icons/compressed.gif) x-compress x-gzip x-bzip2\n\nAddIconByType (TXT,/icons/text.gif) text/*\nAddIconByType (IMG,/icons/image2.gif) image/*\nAddIconByType (SND,/icons/sound2.gif) audio/*\nAddIconByType (VID,/icons/movie.gif) video/*\n\nAddIcon /icons/binary.gif .bin .exe\nAddIcon /icons/binhex.gif .hqx\nAddIcon /icons/tar.gif .tar\nAddIcon /icons/world2.gif .wrl .wrl.gz .vrml .vrm .iv\nAddIcon /icons/compressed.gif .Z .z .tgz .gz .zip\nAddIcon /icons/a.gif .ps .ai .eps\nAddIcon /icons/layout.gif .html .shtml .htm .pdf\nAddIcon /icons/text.gif .txt\nAddIcon /icons/c.gif .c\nAddIcon /icons/p.gif .pl .py\nAddIcon /icons/f.gif .for\nAddIcon /icons/dvi.gif .dvi\nAddIcon /icons/uuencoded.gif .uu\nAddIcon /icons/script.gif .conf .sh .shar .csh .ksh .tcl\nAddIcon /icons/tex.gif .tex\nAddIcon /icons/bomb.gif /core\nAddIcon (SND,/icons/sound2.gif) .ogg\nAddIcon (VID,/icons/movie.gif) .ogm\n\nAddIcon /icons/back.gif ..\nAddIcon /icons/hand.right.gif README\nAddIcon /icons/folder.gif ^^DIRECTORY^^\nAddIcon /icons/blank.gif ^^BLANKICON^^\n\nAddIcon /icons/odf6odt-20x22.png .odt\nAddIcon /icons/odf6ods-20x22.png .ods\nAddIcon /icons/odf6odp-20x22.png .odp\nAddIcon /icons/odf6odg-20x22.png .odg\nAddIcon /icons/odf6odc-20x22.png .odc\nAddIcon /icons/odf6odf-20x22.png .odf\nAddIcon /icons/odf6odb-20x22.png .odb\nAddIcon /icons/odf6odi-20x22.png .odi\nAddIcon /icons/odf6odm-20x22.png .odm\n\nAddIcon /icons/odf6ott-20x22.png .ott\nAddIcon /icons/odf6ots-20x22.png .ots\nAddIcon /icons/odf6otp-20x22.png .otp\nAddIcon /icons/odf6otg-20x22.png .otg\nAddIcon /icons/odf6otc-20x22.png .otc\nAddIcon /icons/odf6otf-20x22.png .otf\nAddIcon /icons/odf6oti-20x22.png .oti\nAddIcon /icons/odf6oth-20x22.png .oth\n\nDefaultIcon /icons/unknown.gif\nReadmeName README.html\nHeaderName HEADER.html\n\nIndexIgnore .??* *~ *# HEADER* README* RCS CVS *,v *,t\n",
      :require => Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"},
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Dav').with(
      :name   => "Apache::Mod::Dav",
      :before => "Class[Apache::Mod::Dav_fs]",
    )
  end

  it do
    expect(subject).to contain_apache__mod('dav').with(
      :name           => "dav",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Dav_fs').with(
      :name => "Apache::Mod::Dav_fs",
    )
  end

  it do
    expect(subject).to contain_apache__mod('dav_fs').with(
      :name           => "dav_fs",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_file('dav_fs.conf').with(
      :path    => "/etc/apache2/mods-available/dav_fs.conf",
      :ensure  => "file",
      :content => "DAVLockDB \"${APACHE_LOCK_DIR}/DAVLock\"\n",
      :require => Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"},
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Deflate').with(
      :name  => "Apache::Mod::Deflate",
      :types => ["text/html text/plain text/xml", "text/css", "application/x-javascript application/javascript application/ecmascript", "application/rss+xml"],
      :notes => {"Input"=>"instream", "Output"=>"outstream", "Ratio"=>"ratio"},
    )
  end

  it do
    expect(subject).to contain_apache__mod('deflate').with(
      :name           => "deflate",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_file('deflate.conf').with(
      :path    => "/etc/apache2/mods-available/deflate.conf",
      :ensure  => "file",
      :content => "AddOutputFilterByType DEFLATE application/rss+xml\nAddOutputFilterByType DEFLATE application/x-javascript application/javascript application/ecmascript\nAddOutputFilterByType DEFLATE text/css\nAddOutputFilterByType DEFLATE text/html text/plain text/xml\n\nDeflateFilterNote Input instream\nDeflateFilterNote Output outstream\nDeflateFilterNote Ratio ratio\n",
      :require => Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"},
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Dir').with(
      :name    => "Apache::Mod::Dir",
      :dir     => "public_html",
      :indexes => ["index.html", "index.html.var", "index.cgi", "index.pl", "index.php", "index.xhtml"],
    )
  end

  it do
    expect(subject).to contain_apache__mod('dir').with(
      :name           => "dir",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_file('dir.conf').with(
      :path    => "/etc/apache2/mods-available/dir.conf",
      :ensure  => "file",
      :content => "DirectoryIndex index.html index.html.var index.cgi index.pl index.php index.xhtml\n",
      :require => Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"},
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Mime').with(
      :name                 => "Apache::Mod::Mime",
      :mime_support_package => "mime-support",
      :mime_types_config    => "/etc/mime.types",
    )
  end

  it do
    expect(subject).to contain_apache__mod('mime').with(
      :name           => "mime",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_file('mime.conf').with(
      :path    => "/etc/apache2/mods-available/mime.conf",
      :ensure  => "file",
      :content => "TypesConfig /etc/mime.types\n\nAddType application/x-compress .Z\nAddType application/x-gzip .gz .tgz\nAddType application/x-bzip2 .bz2\n\nAddLanguage ca .ca\nAddLanguage cs .cz .cs\nAddLanguage da .dk\nAddLanguage de .de\nAddLanguage el .el\nAddLanguage en .en\nAddLanguage eo .eo\nAddLanguage es .es\nAddLanguage et .et\nAddLanguage fr .fr\nAddLanguage he .he\nAddLanguage hr .hr\nAddLanguage it .it\nAddLanguage ja .ja\nAddLanguage ko .ko\nAddLanguage ltz .ltz\nAddLanguage nl .nl\nAddLanguage nn .nn\nAddLanguage no .no\nAddLanguage pl .po\nAddLanguage pt .pt\nAddLanguage pt-BR .pt-br\nAddLanguage ru .ru\nAddLanguage sv .sv\nAddLanguage zh-CN .zh-cn\nAddLanguage zh-TW .zh-tw\n\nAddHandler type-map var\nAddType text/html .shtml\nAddOutputFilter INCLUDES .shtml\n",
      :require => Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"},
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_package('mime-support').with(
      :name   => "mime-support",
      :ensure => "installed",
      :before => File[mime.conf]{:path=>"mime.conf"},
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Negotiation').with(
      :name                    => "Apache::Mod::Negotiation",
      :force_language_priority => "Prefer Fallback",
      :language_priority       => ["en", "ca", "cs", "da", "de", "el", "eo", "es", "et", "fr", "he", "hr", "it", "ja", "ko", "ltz", "nl", "nn", "no", "pl", "pt", "pt-BR", "ru", "sv", "zh-CN", "zh-TW"],
    )
  end

  it do
    expect(subject).to contain_apache__mod('negotiation').with(
      :name           => "negotiation",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_file('negotiation.conf').with(
      :path    => "/etc/apache2/mods-available/negotiation.conf",
      :ensure  => "file",
      :content => "LanguagePriority en ca cs da de el eo es et fr he hr it ja ko ltz nl nn no pl pt pt-BR ru sv zh-CN zh-TW\nForceLanguagePriority Prefer Fallback\n",
      :require => Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"},
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Setenvif').with(
      :name => "Apache::Mod::Setenvif",
    )
  end

  it do
    expect(subject).to contain_apache__mod('setenvif').with(
      :name           => "setenvif",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_file('setenvif.conf').with(
      :path    => "/etc/apache2/mods-available/setenvif.conf",
      :ensure  => "file",
      :content => "#\n# The following directives modify normal HTTP response behavior to\n# handle known problems with browser implementations.\n#\nBrowserMatch \"Mozilla/2\" nokeepalive\nBrowserMatch \"MSIE 4\\.0b2;\" nokeepalive downgrade-1.0 force-response-1.0\nBrowserMatch \"RealPlayer 4\\.0\" force-response-1.0\nBrowserMatch \"Java/1\\.0\" force-response-1.0\nBrowserMatch \"JDK/1\\.0\" force-response-1.0\n\n#\n# The following directive disables redirects on non-GET requests for\n# a directory that does not include the trailing slash.  This fixes a \n# problem with Microsoft WebFolders which does not appropriately handle \n# redirects for folders with DAV methods.\n# Same deal with Apple's DAV filesystem and Gnome VFS support for DAV.\n#\nBrowserMatch \"Microsoft Data Access Internet Publishing Provider\" redirect-carefully\nBrowserMatch \"MS FrontPage\" redirect-carefully\nBrowserMatch \"^WebDrive\" redirect-carefully\nBrowserMatch \"^WebDAVFS/1.[0123]\" redirect-carefully\nBrowserMatch \"^gnome-vfs/1.0\" redirect-carefully\nBrowserMatch \"^gvfs/1\" redirect-carefully\nBrowserMatch \"^XML Spy\" redirect-carefully\nBrowserMatch \"^Dreamweaver-WebDAV-SCM1\" redirect-carefully\nBrowserMatch \" Konqueror/4\" redirect-carefully\n\n<IfModule mod_ssl.c>\n  BrowserMatch \"MSIE [2-6]\" \\\n    nokeepalive ssl-unclean-shutdown \\\n    downgrade-1.0 force-response-1.0\n  # MSIE 7 and newer should be able to use keepalive\n  BrowserMatch \"MSIE [17-9]\" ssl-unclean-shutdown\n</IfModule>\n",
      :require => Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"},
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_apache__mod('auth_basic').with(
      :name           => "auth_basic",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Filter').with(
      :name => "Apache::Mod::Filter",
    )
  end

  it do
    expect(subject).to contain_apache__mod('filter').with(
      :name           => "filter",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_apache__mod('authz_core').with(
      :name           => "authz_core",
      :id             => "authz_core_module",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_apache__mod('access_compat').with(
      :name           => "access_compat",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Authz_user').with(
      :name => "Apache::Mod::Authz_user",
    )
  end

  it do
    expect(subject).to contain_apache__mod('authz_user').with(
      :name           => "authz_user",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_apache__mod('authz_groupfile').with(
      :name           => "authz_groupfile",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_apache__mod('env').with(
      :name           => "env",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_class('Apache::Default_confd_files').with(
      :name => "Apache::Default_confd_files",
      :all  => true,
    )
  end

  it do
    expect(subject).to contain_apache__vhost('default').with(
      :name                 => "default",
      :ensure               => "absent",
      :port                 => "80",
      :docroot              => "/var/www",
      :scriptalias          => "/usr/lib/cgi-bin",
      :serveradmin          => "root@localhost",
      :access_log_file      => "access.log",
      :priority             => "15",
      :manage_docroot       => false,
      :virtual_docroot      => false,
      :ip_based             => false,
      :add_listen           => true,
      :docroot_owner        => "root",
      :docroot_group        => "root",
      :ssl                  => false,
      :ssl_cert             => "/etc/ssl/certs/ssl-cert-snakeoil.pem",
      :ssl_key              => "/etc/ssl/private/ssl-cert-snakeoil.key",
      :ssl_certs_dir        => "/etc/ssl/certs",
      :ssl_proxyengine      => false,
      :default_vhost        => false,
      :servername           => "default",
      :serveraliases        => [],
      :options              => ["Indexes", "FollowSymLinks", "MultiViews"],
      :override             => "None",
      :directoryindex       => "",
      :vhost_name           => "*",
      :logroot              => "/var/log/apache2",
      :logroot_ensure       => "directory",
      :access_log           => true,
      :access_log_pipe      => false,
      :access_log_syslog    => false,
      :access_log_format    => false,
      :access_log_env_var   => false,
      :error_log            => true,
      :error_documents      => [],
      :scriptaliases        => {"alias"=>"/cgi-bin", "path"=>"/usr/lib/cgi-bin"},
      :suphp_addhandler     => "x-httpd-php",
      :suphp_engine         => "off",
      :suphp_configpath     => "/etc/php5/apache2",
      :php_flags            => {},
      :php_values           => {},
      :php_admin_flags      => {},
      :php_admin_values     => {},
      :no_proxy_uris        => [],
      :no_proxy_uris_match  => [],
      :proxy_preserve_host  => false,
      :proxy_error_override => false,
      :redirect_source      => "/",
      :setenv               => [],
      :setenvif             => [],
      :block                => [],
      :additional_includes  => [],
      :apache_version       => "2.4",
    )
  end

  it do
    expect(subject).to contain_apache__vhost('default-ssl').with(
      :name                 => "default-ssl",
      :ensure               => "absent",
      :port                 => "443",
      :ssl                  => true,
      :docroot              => "/var/www",
      :scriptalias          => "/usr/lib/cgi-bin",
      :serveradmin          => "root@localhost",
      :access_log_file      => "ssl_access.log",
      :priority             => "15",
      :manage_docroot       => false,
      :virtual_docroot      => false,
      :ip_based             => false,
      :add_listen           => true,
      :docroot_owner        => "root",
      :docroot_group        => "root",
      :ssl_cert             => "/etc/ssl/certs/ssl-cert-snakeoil.pem",
      :ssl_key              => "/etc/ssl/private/ssl-cert-snakeoil.key",
      :ssl_certs_dir        => "/etc/ssl/certs",
      :ssl_proxyengine      => false,
      :default_vhost        => false,
      :servername           => "default-ssl",
      :serveraliases        => [],
      :options              => ["Indexes", "FollowSymLinks", "MultiViews"],
      :override             => "None",
      :directoryindex       => "",
      :vhost_name           => "*",
      :logroot              => "/var/log/apache2",
      :logroot_ensure       => "directory",
      :access_log           => true,
      :access_log_pipe      => false,
      :access_log_syslog    => false,
      :access_log_format    => false,
      :access_log_env_var   => false,
      :error_log            => true,
      :error_documents      => [],
      :scriptaliases        => {"alias"=>"/cgi-bin", "path"=>"/usr/lib/cgi-bin"},
      :suphp_addhandler     => "x-httpd-php",
      :suphp_engine         => "off",
      :suphp_configpath     => "/etc/php5/apache2",
      :php_flags            => {},
      :php_values           => {},
      :php_admin_flags      => {},
      :php_admin_values     => {},
      :no_proxy_uris        => [],
      :no_proxy_uris_match  => [],
      :proxy_preserve_host  => false,
      :proxy_error_override => false,
      :redirect_source      => "/",
      :setenv               => [],
      :setenvif             => [],
      :block                => [],
      :additional_includes  => [],
      :apache_version       => "2.4",
    )
  end

  it do
    expect(subject).to contain_osnailyfacter__apache__apache_port('80').with(
      :name => "80",
    )
  end

  it do
    expect(subject).to contain_osnailyfacter__apache__apache_port('8888').with(
      :name => "8888",
    )
  end

  it do
    expect(subject).to contain_osnailyfacter__apache__apache_port('5000').with(
      :name => "5000",
    )
  end

  it do
    expect(subject).to contain_osnailyfacter__apache__apache_port('35357').with(
      :name => "35357",
    )
  end

  it do
    expect(subject).to contain_file('/etc/logrotate.d/apache2').with(
      :path    => "/etc/logrotate.d/apache2",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "# This file managed via puppet\n/var/log/apache2/*.log {\n    weekly\n    missingok\n    rotate 52\n    compress\n    delaycompress\n    notifempty\n    create 640 root adm\n    sharedscripts\n    postrotate\n       if /etc/init.d/apache2 status > /dev/null ; then \\\n           (/usr/sbin/apachectl graceful) || (/usr/sbin/apachectl restart)\n       fi;\n    endscript\n    prerotate\n        if [ -d /etc/logrotate.d/httpd-prerotate ]; then \\\n            run-parts /etc/logrotate.d/httpd-prerotate; \\\n        fi; \\\n    endscript\n}\n",
      :require => Package[httpd]{:name=>"httpd"},
    )
  end

  it do
    expect(subject).to contain_file('/etc/logrotate.d/httpd-prerotate').with(
      :path   => "/etc/logrotate.d/httpd-prerotate",
      :ensure => "directory",
      :owner  => "root",
      :group  => "root",
      :mode   => "0755",
    )
  end

  it do
    expect(subject).to contain_file('/etc/logrotate.d/httpd-prerotate/apache2').with(
      :path    => "/etc/logrotate.d/httpd-prerotate/apache2",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0755",
      :content => "#!/bin/sh\n# This is a prerotate script for apache2 that will add a delay to the log\n# rotation to spread out the apache2 restarts. The goal of this script is to\n# stager the apache restarts to prevent all services from being down at the\n# same time. LP#1491576\n\nsleep 240\n",
    )
  end

  it do
    expect(subject).to contain_class('Osnailyfacter::Apache_api_proxy').with(
      :name            => "Osnailyfacter::Apache_api_proxy",
      :master_ip       => "10.108.0.2",
      :max_header_size => "81900",
    )
  end

  it do
    expect(subject).to contain_firewall('007 tinyproxy').with(
      :name   => "007 tinyproxy",
      :dport  => "8888",
      :source => "10.108.0.2",
      :proto  => "tcp",
      :action => "accept",
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Proxy').with(
      :name           => "Apache::Mod::Proxy",
      :proxy_requests => "Off",
      :apache_version => "2.4",
      :before         => ["Class[Apache::Mod::Proxy_connect]", "Class[Apache::Mod::Proxy_http]"],
    )
  end

  it do
    expect(subject).to contain_apache__mod('proxy').with(
      :name           => "proxy",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_file('proxy.conf').with(
      :path    => "/etc/apache2/mods-available/proxy.conf",
      :ensure  => "file",
      :content => "#\n# Proxy Server directives. Uncomment the following lines to\n# enable the proxy server:\n#\n<IfModule mod_proxy.c>\n  # Do not enable proxying with ProxyRequests until you have secured your\n  # server.  Open proxy servers are dangerous both to your network and to the\n  # Internet at large.\n  ProxyRequests Off\n\n  \n  # Enable/disable the handling of HTTP/1.1 \"Via:\" headers.\n  # (\"Full\" adds the server version; \"Block\" removes all outgoing Via: headers)\n  # Set to one of: Off | On | Full | Block\n  ProxyVia On\n</IfModule>\n",
      :require => Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"},
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Proxy_connect').with(
      :name           => "Apache::Mod::Proxy_connect",
      :apache_version => "2.4",
    )
  end

  it do
    expect(subject).to contain_apache__mod('proxy_connect').with(
      :name           => "proxy_connect",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_class('Apache::Mod::Proxy_http').with(
      :name => "Apache::Mod::Proxy_http",
    )
  end

  it do
    expect(subject).to contain_apache__mod('proxy_http').with(
      :name           => "proxy_http",
      :package_ensure => "present",
      :lib_path       => "/usr/lib/apache2/modules",
    )
  end

  it do
    expect(subject).to contain_apache__vhost('apache_api_proxy').with(
      :name                 => "apache_api_proxy",
      :docroot              => "/var/www/html",
      :custom_fragment      => "  ProxyRequests on\n  ProxyVia On\n  AllowCONNECT 443 563 5000 8000 8003 8004 8080 8082 8386 8773 8774 8776 8777 9292 9696\n  HostnameLookups off\n  LimitRequestFieldSize 81900\n  <Proxy *>\n    Order Deny,Allow\n        Allow from 10.108.0.2\n        Deny from all\n  </Proxy>\n",
      :port                 => "8888",
      :add_listen           => true,
      :error_log_syslog     => "syslog:local0",
      :log_level            => "notice",
      :manage_docroot       => true,
      :virtual_docroot      => false,
      :ip_based             => false,
      :docroot_owner        => "root",
      :docroot_group        => "root",
      :ssl                  => false,
      :ssl_cert             => "/etc/ssl/certs/ssl-cert-snakeoil.pem",
      :ssl_key              => "/etc/ssl/private/ssl-cert-snakeoil.key",
      :ssl_certs_dir        => "/etc/ssl/certs",
      :ssl_proxyengine      => false,
      :default_vhost        => false,
      :servername           => "apache_api_proxy",
      :serveraliases        => [],
      :options              => ["Indexes", "FollowSymLinks", "MultiViews"],
      :override             => "None",
      :directoryindex       => "",
      :vhost_name           => "*",
      :logroot              => "/var/log/apache2",
      :logroot_ensure       => "directory",
      :access_log           => true,
      :access_log_file      => false,
      :access_log_pipe      => false,
      :access_log_syslog    => false,
      :access_log_format    => false,
      :access_log_env_var   => false,
      :error_log            => true,
      :error_documents      => [],
      :scriptaliases        => [],
      :suphp_addhandler     => "x-httpd-php",
      :suphp_engine         => "off",
      :suphp_configpath     => "/etc/php5/apache2",
      :php_flags            => {},
      :php_values           => {},
      :php_admin_flags      => {},
      :php_admin_values     => {},
      :no_proxy_uris        => [],
      :no_proxy_uris_match  => [],
      :proxy_preserve_host  => false,
      :proxy_error_override => false,
      :redirect_source      => "/",
      :setenv               => [],
      :setenvif             => [],
      :block                => [],
      :ensure               => "present",
      :additional_includes  => [],
      :apache_version       => "2.4",
    )
  end

  it do
    expect(subject).to contain_class('Tweaks::Apache_wrappers').with(
      :name => "Tweaks::Apache_wrappers",
    )
  end

  it do
    expect(subject).to contain_class('Concat::Setup').with(
      :name => "Concat::Setup",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//bin/concatfragments.rb').with(
      :path   => "/tmp//bin/concatfragments.rb",
      :ensure => "file",
      :mode   => "0755",
      :source => "puppet:///modules/concat/concatfragments.rb",
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp/').with(
      :path   => "/tmp",
      :ensure => "directory",
      :mode   => "0755",
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//bin').with(
      :path   => "/tmp//bin",
      :ensure => "directory",
      :mode   => "0755",
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//_etc_apache2_ports.conf').with(
      :path   => "/tmp//_etc_apache2_ports.conf",
      :ensure => "directory",
      :mode   => "0750",
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//_etc_apache2_ports.conf/fragments').with(
      :path    => "/tmp//_etc_apache2_ports.conf/fragments",
      :ensure  => "directory",
      :mode    => "0750",
      :force   => true,
      :ignore  => [".svn", ".git", ".gitignore"],
      :notify  => Exec[concat_/etc/apache2/ports.conf]{:command=>"concat_/etc/apache2/ports.conf"},
      :purge   => true,
      :recurse => true,
      :backup  => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//_etc_apache2_ports.conf/fragments.concat').with(
      :path   => "/tmp//_etc_apache2_ports.conf/fragments.concat",
      :ensure => "present",
      :mode   => "0640",
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//_etc_apache2_ports.conf/fragments.concat.out').with(
      :path   => "/tmp//_etc_apache2_ports.conf/fragments.concat.out",
      :ensure => "present",
      :mode   => "0640",
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/etc/apache2/ports.conf').with(
      :path    => "/etc/apache2/ports.conf",
      :ensure  => "present",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :replace => true,
      :alias   => "concat_/etc/apache2/ports.conf",
      :source  => "/tmp//_etc_apache2_ports.conf/fragments.concat.out",
      :backup  => "puppet",
    )
  end

  it do
    expect(subject).to contain_exec('concat_/etc/apache2/ports.conf').with(
      :command   => "/tmp//bin/concatfragments.rb -o \"/tmp//_etc_apache2_ports.conf/fragments.concat.out\" -d \"/tmp//_etc_apache2_ports.conf\"",
      :alias     => "concat_/tmp//_etc_apache2_ports.conf",
      :notify    => File[/etc/apache2/ports.conf]{:path=>"/etc/apache2/ports.conf"},
      :subscribe => File[/tmp//_etc_apache2_ports.conf]{:path=>"/tmp//_etc_apache2_ports.conf"},
      :unless    => "/tmp//bin/concatfragments.rb -o \"/tmp//_etc_apache2_ports.conf/fragments.concat.out\" -d \"/tmp//_etc_apache2_ports.conf\" -t",
      :require   => [File[/tmp//_etc_apache2_ports.conf]{:path=>"/tmp//_etc_apache2_ports.conf"}, File[/tmp//_etc_apache2_ports.conf/fragments]{:path=>"/tmp//_etc_apache2_ports.conf/fragments"}, File[/tmp//_etc_apache2_ports.conf/fragments.concat]{:path=>"/tmp//_etc_apache2_ports.conf/fragments.concat"}],
    )
  end

  it do
    expect(subject).to contain_file('/tmp//_etc_apache2_ports.conf/fragments/10_Apache ports header').with(
      :path    => "/tmp//_etc_apache2_ports.conf/fragments/10_Apache ports header",
      :ensure  => "file",
      :mode    => "0640",
      :content => "# ************************************\n# Listen & NameVirtualHost resources in module puppetlabs-apache\n# Managed by Puppet\n# ************************************\n\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_Apache ports header",
      :notify  => Exec[concat_/etc/apache2/ports.conf]{:command=>"concat_/etc/apache2/ports.conf"},
    )
  end

  it do
    expect(subject).to contain_file('authz_host.load').with(
      :path    => "/etc/apache2/mods-available/authz_host.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule authz_host_module /usr/lib/apache2/modules/mod_authz_host.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('authz_host.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/authz_host.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/authz_host.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[authz_host.load]{:path=>"authz_host.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('authn_core.load').with(
      :path    => "/etc/apache2/mods-available/authn_core.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule authn_core_module /usr/lib/apache2/modules/mod_authn_core.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('authn_core.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/authn_core.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/authn_core.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[authn_core.load]{:path=>"authn_core.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('reqtimeout.load').with(
      :path    => "/etc/apache2/mods-available/reqtimeout.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule reqtimeout_module /usr/lib/apache2/modules/mod_reqtimeout.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('reqtimeout.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/reqtimeout.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/reqtimeout.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[reqtimeout.load]{:path=>"reqtimeout.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('reqtimeout.conf symlink').with(
      :path    => "/etc/apache2/mods-enabled/reqtimeout.conf",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/reqtimeout.conf",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[reqtimeout.conf]{:path=>"reqtimeout.conf"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('alias.load').with(
      :path    => "/etc/apache2/mods-available/alias.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule alias_module /usr/lib/apache2/modules/mod_alias.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('alias.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/alias.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/alias.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[alias.load]{:path=>"alias.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('alias.conf symlink').with(
      :path    => "/etc/apache2/mods-enabled/alias.conf",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/alias.conf",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[alias.conf]{:path=>"alias.conf"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('authn_file.load').with(
      :path    => "/etc/apache2/mods-available/authn_file.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule authn_file_module /usr/lib/apache2/modules/mod_authn_file.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('authn_file.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/authn_file.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/authn_file.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[authn_file.load]{:path=>"authn_file.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('autoindex.load').with(
      :path    => "/etc/apache2/mods-available/autoindex.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule autoindex_module /usr/lib/apache2/modules/mod_autoindex.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('autoindex.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/autoindex.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/autoindex.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[autoindex.load]{:path=>"autoindex.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('autoindex.conf symlink').with(
      :path    => "/etc/apache2/mods-enabled/autoindex.conf",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/autoindex.conf",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[autoindex.conf]{:path=>"autoindex.conf"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('dav.load').with(
      :path    => "/etc/apache2/mods-available/dav.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule dav_module /usr/lib/apache2/modules/mod_dav.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('dav.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/dav.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/dav.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[dav.load]{:path=>"dav.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('dav_fs.load').with(
      :path    => "/etc/apache2/mods-available/dav_fs.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule dav_fs_module /usr/lib/apache2/modules/mod_dav_fs.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('dav_fs.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/dav_fs.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/dav_fs.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[dav_fs.load]{:path=>"dav_fs.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('dav_fs.conf symlink').with(
      :path    => "/etc/apache2/mods-enabled/dav_fs.conf",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/dav_fs.conf",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[dav_fs.conf]{:path=>"dav_fs.conf"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('deflate.load').with(
      :path    => "/etc/apache2/mods-available/deflate.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule deflate_module /usr/lib/apache2/modules/mod_deflate.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('deflate.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/deflate.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/deflate.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[deflate.load]{:path=>"deflate.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('deflate.conf symlink').with(
      :path    => "/etc/apache2/mods-enabled/deflate.conf",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/deflate.conf",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[deflate.conf]{:path=>"deflate.conf"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('dir.load').with(
      :path    => "/etc/apache2/mods-available/dir.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule dir_module /usr/lib/apache2/modules/mod_dir.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('dir.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/dir.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/dir.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[dir.load]{:path=>"dir.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('dir.conf symlink').with(
      :path    => "/etc/apache2/mods-enabled/dir.conf",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/dir.conf",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[dir.conf]{:path=>"dir.conf"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('mime.load').with(
      :path    => "/etc/apache2/mods-available/mime.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule mime_module /usr/lib/apache2/modules/mod_mime.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('mime.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/mime.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/mime.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[mime.load]{:path=>"mime.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('mime.conf symlink').with(
      :path    => "/etc/apache2/mods-enabled/mime.conf",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/mime.conf",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[mime.conf]{:path=>"mime.conf"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('negotiation.load').with(
      :path    => "/etc/apache2/mods-available/negotiation.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule negotiation_module /usr/lib/apache2/modules/mod_negotiation.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('negotiation.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/negotiation.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/negotiation.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[negotiation.load]{:path=>"negotiation.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('negotiation.conf symlink').with(
      :path    => "/etc/apache2/mods-enabled/negotiation.conf",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/negotiation.conf",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[negotiation.conf]{:path=>"negotiation.conf"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('setenvif.load').with(
      :path    => "/etc/apache2/mods-available/setenvif.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule setenvif_module /usr/lib/apache2/modules/mod_setenvif.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('setenvif.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/setenvif.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/setenvif.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[setenvif.load]{:path=>"setenvif.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('setenvif.conf symlink').with(
      :path    => "/etc/apache2/mods-enabled/setenvif.conf",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/setenvif.conf",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[setenvif.conf]{:path=>"setenvif.conf"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('auth_basic.load').with(
      :path    => "/etc/apache2/mods-available/auth_basic.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule auth_basic_module /usr/lib/apache2/modules/mod_auth_basic.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('auth_basic.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/auth_basic.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/auth_basic.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[auth_basic.load]{:path=>"auth_basic.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('filter.load').with(
      :path    => "/etc/apache2/mods-available/filter.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule filter_module /usr/lib/apache2/modules/mod_filter.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('filter.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/filter.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/filter.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[filter.load]{:path=>"filter.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('authz_core.load').with(
      :path    => "/etc/apache2/mods-available/authz_core.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule authz_core_module /usr/lib/apache2/modules/mod_authz_core.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('authz_core.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/authz_core.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/authz_core.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[authz_core.load]{:path=>"authz_core.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('access_compat.load').with(
      :path    => "/etc/apache2/mods-available/access_compat.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule access_compat_module /usr/lib/apache2/modules/mod_access_compat.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('access_compat.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/access_compat.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/access_compat.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[access_compat.load]{:path=>"access_compat.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('authz_user.load').with(
      :path    => "/etc/apache2/mods-available/authz_user.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule authz_user_module /usr/lib/apache2/modules/mod_authz_user.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('authz_user.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/authz_user.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/authz_user.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[authz_user.load]{:path=>"authz_user.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('authz_groupfile.load').with(
      :path    => "/etc/apache2/mods-available/authz_groupfile.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule authz_groupfile_module /usr/lib/apache2/modules/mod_authz_groupfile.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('authz_groupfile.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/authz_groupfile.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/authz_groupfile.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[authz_groupfile.load]{:path=>"authz_groupfile.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('env.load').with(
      :path    => "/etc/apache2/mods-available/env.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule env_module /usr/lib/apache2/modules/mod_env.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('env.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/env.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/env.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[env.load]{:path=>"env.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('/var/log/apache2').with(
      :path    => "/var/log/apache2",
      :ensure  => "directory",
      :require => Package[httpd]{:name=>"httpd"},
      :before  => Concat[15-default.conf]{:name=>"15-default.conf"},
    )
  end

  it do
    expect(subject).to contain_concat('15-default.conf').with(
      :name           => "15-default.conf",
      :ensure         => "absent",
      :path           => "/etc/apache2/sites-available/15-default.conf",
      :owner          => "root",
      :group          => "root",
      :mode           => "0644",
      :order          => "numeric",
      :require        => Package[httpd]{:name=>"httpd"},
      :notify         => Class[Apache::Service]{:name=>"Apache::Service"},
      :warn           => false,
      :force          => false,
      :backup         => "puppet",
      :replace        => true,
      :ensure_newline => false,
    )
  end

  it do
    expect(subject).to contain_file('15-default.conf symlink').with(
      :path    => "/etc/apache2/sites-enabled/15-default.conf",
      :ensure  => "absent",
      :target  => "/etc/apache2/sites-available/15-default.conf",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => Concat[15-default.conf]{:name=>"15-default.conf"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-apache-header').with(
      :name    => "default-apache-header",
      :target  => "15-default.conf",
      :order   => "0",
      :content => "# ************************************\n# Vhost template in module puppetlabs-apache\n# Managed by Puppet\n# ************************************\n\n<VirtualHost *:80>\n  ServerName default\n  ServerAdmin root@localhost\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-docroot').with(
      :name    => "default-docroot",
      :target  => "15-default.conf",
      :order   => "10",
      :content => "\n  ## Vhost docroot\n  DocumentRoot \"/var/www\"\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-directories').with(
      :name    => "default-directories",
      :target  => "15-default.conf",
      :order   => "60",
      :content => "\n  ## Directories, there should at least be a declaration for /var/www\n\n  <Directory \"/var/www\">\n    Options Indexes FollowSymLinks MultiViews\n    AllowOverride None\n    Require all granted\n  </Directory>\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-logging').with(
      :name    => "default-logging",
      :target  => "15-default.conf",
      :order   => "80",
      :content => "\n  ## Logging\n  ErrorLog \"/var/log/apache2/default_error.log\"\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-serversignature').with(
      :name    => "default-serversignature",
      :target  => "15-default.conf",
      :order   => "90",
      :content => "  ServerSignature Off\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-access_log').with(
      :name    => "default-access_log",
      :target  => "15-default.conf",
      :order   => "100",
      :content => "  CustomLog \"/var/log/apache2/access.log\" combined \n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-scriptalias').with(
      :name    => "default-scriptalias",
      :target  => "15-default.conf",
      :order   => "180",
      :content => "  ## Script alias directives\n  ScriptAlias /cgi-bin \"/usr/lib/cgi-bin\"\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-file_footer').with(
      :name    => "default-file_footer",
      :target  => "15-default.conf",
      :order   => "999",
      :content => "</VirtualHost>\n",
    )
  end

  it do
    expect(subject).to contain_concat('15-default-ssl.conf').with(
      :name           => "15-default-ssl.conf",
      :ensure         => "absent",
      :path           => "/etc/apache2/sites-available/15-default-ssl.conf",
      :owner          => "root",
      :group          => "root",
      :mode           => "0644",
      :order          => "numeric",
      :require        => Package[httpd]{:name=>"httpd"},
      :notify         => Class[Apache::Service]{:name=>"Apache::Service"},
      :warn           => false,
      :force          => false,
      :backup         => "puppet",
      :replace        => true,
      :ensure_newline => false,
    )
  end

  it do
    expect(subject).to contain_file('15-default-ssl.conf symlink').with(
      :path    => "/etc/apache2/sites-enabled/15-default-ssl.conf",
      :ensure  => "absent",
      :target  => "/etc/apache2/sites-available/15-default-ssl.conf",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => Concat[15-default-ssl.conf]{:name=>"15-default-ssl.conf"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-ssl-apache-header').with(
      :name    => "default-ssl-apache-header",
      :target  => "15-default-ssl.conf",
      :order   => "0",
      :content => "# ************************************\n# Vhost template in module puppetlabs-apache\n# Managed by Puppet\n# ************************************\n\n<VirtualHost *:443>\n  ServerName default-ssl\n  ServerAdmin root@localhost\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-ssl-docroot').with(
      :name    => "default-ssl-docroot",
      :target  => "15-default-ssl.conf",
      :order   => "10",
      :content => "\n  ## Vhost docroot\n  DocumentRoot \"/var/www\"\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-ssl-directories').with(
      :name    => "default-ssl-directories",
      :target  => "15-default-ssl.conf",
      :order   => "60",
      :content => "\n  ## Directories, there should at least be a declaration for /var/www\n\n  <Directory \"/var/www\">\n    Options Indexes FollowSymLinks MultiViews\n    AllowOverride None\n    Require all granted\n  </Directory>\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-ssl-logging').with(
      :name    => "default-ssl-logging",
      :target  => "15-default-ssl.conf",
      :order   => "80",
      :content => "\n  ## Logging\n  ErrorLog \"/var/log/apache2/default-ssl_error_ssl.log\"\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-ssl-serversignature').with(
      :name    => "default-ssl-serversignature",
      :target  => "15-default-ssl.conf",
      :order   => "90",
      :content => "  ServerSignature Off\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-ssl-access_log').with(
      :name    => "default-ssl-access_log",
      :target  => "15-default-ssl.conf",
      :order   => "100",
      :content => "  CustomLog \"/var/log/apache2/ssl_access.log\" combined \n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-ssl-scriptalias').with(
      :name    => "default-ssl-scriptalias",
      :target  => "15-default-ssl.conf",
      :order   => "180",
      :content => "  ## Script alias directives\n  ScriptAlias /cgi-bin \"/usr/lib/cgi-bin\"\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-ssl-ssl').with(
      :name    => "default-ssl-ssl",
      :target  => "15-default-ssl.conf",
      :order   => "210",
      :content => "\n  ## SSL directives\n  SSLEngine on\n  SSLCertificateFile      \"/etc/ssl/certs/ssl-cert-snakeoil.pem\"\n  SSLCertificateKeyFile   \"/etc/ssl/private/ssl-cert-snakeoil.key\"\n  SSLCACertificatePath    \"/etc/ssl/certs\"\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('default-ssl-file_footer').with(
      :name    => "default-ssl-file_footer",
      :target  => "15-default-ssl.conf",
      :order   => "999",
      :content => "</VirtualHost>\n",
    )
  end

  it do
    expect(subject).to contain_apache__listen('80').with(
      :name => "80",
    )
  end

  it do
    expect(subject).to contain_apache__namevirtualhost('*:80').with(
      :name => "*:80",
    )
  end

  it do
    expect(subject).to contain_apache__listen('8888').with(
      :name => "8888",
    )
  end

  it do
    expect(subject).to contain_apache__namevirtualhost('*:8888').with(
      :name => "*:8888",
    )
  end

  it do
    expect(subject).to contain_apache__listen('5000').with(
      :name => "5000",
    )
  end

  it do
    expect(subject).to contain_apache__namevirtualhost('*:5000').with(
      :name => "*:5000",
    )
  end

  it do
    expect(subject).to contain_apache__listen('35357').with(
      :name => "35357",
    )
  end

  it do
    expect(subject).to contain_apache__namevirtualhost('*:35357').with(
      :name => "*:35357",
    )
  end

  it do
    expect(subject).to contain_file('proxy.load').with(
      :path    => "/etc/apache2/mods-available/proxy.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule proxy_module /usr/lib/apache2/modules/mod_proxy.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('proxy.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/proxy.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/proxy.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[proxy.load]{:path=>"proxy.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('proxy.conf symlink').with(
      :path    => "/etc/apache2/mods-enabled/proxy.conf",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/proxy.conf",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[proxy.conf]{:path=>"proxy.conf"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('proxy_connect.load').with(
      :path    => "/etc/apache2/mods-available/proxy_connect.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule proxy_connect_module /usr/lib/apache2/modules/mod_proxy_connect.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('proxy_connect.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/proxy_connect.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/proxy_connect.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[proxy_connect.load]{:path=>"proxy_connect.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('proxy_http.load').with(
      :path    => "/etc/apache2/mods-available/proxy_http.load",
      :ensure  => "file",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :content => "LoadModule proxy_http_module /usr/lib/apache2/modules/mod_proxy_http.so\n",
      :require => [Package[httpd]{:name=>"httpd"}, Exec[mkdir /etc/apache2/mods-available]{:command=>"mkdir /etc/apache2/mods-available"}],
      :before  => File[/etc/apache2/mods-available]{:path=>"/etc/apache2/mods-available"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('proxy_http.load symlink').with(
      :path    => "/etc/apache2/mods-enabled/proxy_http.load",
      :ensure  => "link",
      :target  => "/etc/apache2/mods-available/proxy_http.load",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => [File[proxy_http.load]{:path=>"proxy_http.load"}, Exec[mkdir /etc/apache2/mods-enabled]{:command=>"mkdir /etc/apache2/mods-enabled"}],
      :before  => File[/etc/apache2/mods-enabled]{:path=>"/etc/apache2/mods-enabled"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_file('/var/www/html').with(
      :path    => "/var/www/html",
      :ensure  => "directory",
      :owner   => "root",
      :group   => "root",
      :require => Package[httpd]{:name=>"httpd"},
      :before  => Concat[25-apache_api_proxy.conf]{:name=>"25-apache_api_proxy.conf"},
    )
  end

  it do
    expect(subject).to contain_concat('25-apache_api_proxy.conf').with(
      :name           => "25-apache_api_proxy.conf",
      :ensure         => "present",
      :path           => "/etc/apache2/sites-available/25-apache_api_proxy.conf",
      :owner          => "root",
      :group          => "root",
      :mode           => "0644",
      :order          => "numeric",
      :require        => Package[httpd]{:name=>"httpd"},
      :notify         => Class[Apache::Service]{:name=>"Apache::Service"},
      :warn           => false,
      :force          => false,
      :backup         => "puppet",
      :replace        => true,
      :ensure_newline => false,
    )
  end

  it do
    expect(subject).to contain_file('25-apache_api_proxy.conf symlink').with(
      :path    => "/etc/apache2/sites-enabled/25-apache_api_proxy.conf",
      :ensure  => "link",
      :target  => "/etc/apache2/sites-available/25-apache_api_proxy.conf",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :require => Concat[25-apache_api_proxy.conf]{:name=>"25-apache_api_proxy.conf"},
      :notify  => Class[Apache::Service]{:name=>"Apache::Service"},
    )
  end

  it do
    expect(subject).to contain_concat__fragment('apache_api_proxy-apache-header').with(
      :name    => "apache_api_proxy-apache-header",
      :target  => "25-apache_api_proxy.conf",
      :order   => "0",
      :content => "# ************************************\n# Vhost template in module puppetlabs-apache\n# Managed by Puppet\n# ************************************\n\n<VirtualHost *:8888>\n  ServerName apache_api_proxy\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('apache_api_proxy-docroot').with(
      :name    => "apache_api_proxy-docroot",
      :target  => "25-apache_api_proxy.conf",
      :order   => "10",
      :content => "\n  ## Vhost docroot\n  DocumentRoot \"/var/www/html\"\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('apache_api_proxy-directories').with(
      :name    => "apache_api_proxy-directories",
      :target  => "25-apache_api_proxy.conf",
      :order   => "60",
      :content => "\n  ## Directories, there should at least be a declaration for /var/www/html\n\n  <Directory \"/var/www/html\">\n    Options Indexes FollowSymLinks MultiViews\n    AllowOverride None\n    Require all granted\n  </Directory>\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('apache_api_proxy-logging').with(
      :name    => "apache_api_proxy-logging",
      :target  => "25-apache_api_proxy.conf",
      :order   => "80",
      :content => "\n  ## Logging\n  ErrorLog \"syslog:local0\"\n  LogLevel notice\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('apache_api_proxy-serversignature').with(
      :name    => "apache_api_proxy-serversignature",
      :target  => "25-apache_api_proxy.conf",
      :order   => "90",
      :content => "  ServerSignature Off\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('apache_api_proxy-access_log').with(
      :name    => "apache_api_proxy-access_log",
      :target  => "25-apache_api_proxy.conf",
      :order   => "100",
      :content => "  CustomLog \"/var/log/apache2/apache_api_proxy_access.log\" combined \n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('apache_api_proxy-custom_fragment').with(
      :name    => "apache_api_proxy-custom_fragment",
      :target  => "25-apache_api_proxy.conf",
      :order   => "270",
      :content => "\n  ## Custom fragment\n  ProxyRequests on\n  ProxyVia On\n  AllowCONNECT 443 563 5000 8000 8003 8004 8080 8082 8386 8773 8774 8776 8777 9292 9696\n  HostnameLookups off\n  LimitRequestFieldSize 81900\n  <Proxy *>\n    Order Deny,Allow\n        Allow from 10.108.0.2\n        Deny from all\n  </Proxy>\n\n",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('apache_api_proxy-file_footer').with(
      :name    => "apache_api_proxy-file_footer",
      :target  => "25-apache_api_proxy.conf",
      :order   => "999",
      :content => "</VirtualHost>\n",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default.conf').with(
      :path   => "/tmp//15-default.conf",
      :ensure => "absent",
      :force  => true,
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default.conf/fragments').with(
      :path   => "/tmp//15-default.conf/fragments",
      :ensure => "absent",
      :force  => true,
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default.conf/fragments.concat').with(
      :path   => "/tmp//15-default.conf/fragments.concat",
      :ensure => "absent",
      :force  => true,
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default.conf/fragments.concat.out').with(
      :path   => "/tmp//15-default.conf/fragments.concat.out",
      :ensure => "absent",
      :force  => true,
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/etc/apache2/sites-available/15-default.conf').with(
      :path   => "/etc/apache2/sites-available/15-default.conf",
      :ensure => "absent",
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_exec('concat_15-default.conf').with(
      :command => "true",
      :alias   => "concat_/tmp//15-default.conf",
      :unless  => "true",
      :path    => "/bin:/usr/bin",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default.conf/fragments/0_default-apache-header').with(
      :path    => "/tmp//15-default.conf/fragments/0_default-apache-header",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "# ************************************\n# Vhost template in module puppetlabs-apache\n# Managed by Puppet\n# ************************************\n\n<VirtualHost *:80>\n  ServerName default\n  ServerAdmin root@localhost\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-apache-header",
      :notify  => Exec[concat_15-default.conf]{:command=>"concat_15-default.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default.conf/fragments/10_default-docroot').with(
      :path    => "/tmp//15-default.conf/fragments/10_default-docroot",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "\n  ## Vhost docroot\n  DocumentRoot \"/var/www\"\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-docroot",
      :notify  => Exec[concat_15-default.conf]{:command=>"concat_15-default.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default.conf/fragments/60_default-directories').with(
      :path    => "/tmp//15-default.conf/fragments/60_default-directories",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "\n  ## Directories, there should at least be a declaration for /var/www\n\n  <Directory \"/var/www\">\n    Options Indexes FollowSymLinks MultiViews\n    AllowOverride None\n    Require all granted\n  </Directory>\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-directories",
      :notify  => Exec[concat_15-default.conf]{:command=>"concat_15-default.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default.conf/fragments/80_default-logging').with(
      :path    => "/tmp//15-default.conf/fragments/80_default-logging",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "\n  ## Logging\n  ErrorLog \"/var/log/apache2/default_error.log\"\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-logging",
      :notify  => Exec[concat_15-default.conf]{:command=>"concat_15-default.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default.conf/fragments/90_default-serversignature').with(
      :path    => "/tmp//15-default.conf/fragments/90_default-serversignature",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "  ServerSignature Off\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-serversignature",
      :notify  => Exec[concat_15-default.conf]{:command=>"concat_15-default.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default.conf/fragments/100_default-access_log').with(
      :path    => "/tmp//15-default.conf/fragments/100_default-access_log",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "  CustomLog \"/var/log/apache2/access.log\" combined \n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-access_log",
      :notify  => Exec[concat_15-default.conf]{:command=>"concat_15-default.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default.conf/fragments/180_default-scriptalias').with(
      :path    => "/tmp//15-default.conf/fragments/180_default-scriptalias",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "  ## Script alias directives\n  ScriptAlias /cgi-bin \"/usr/lib/cgi-bin\"\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-scriptalias",
      :notify  => Exec[concat_15-default.conf]{:command=>"concat_15-default.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default.conf/fragments/999_default-file_footer').with(
      :path    => "/tmp//15-default.conf/fragments/999_default-file_footer",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "</VirtualHost>\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-file_footer",
      :notify  => Exec[concat_15-default.conf]{:command=>"concat_15-default.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default-ssl.conf').with(
      :path   => "/tmp//15-default-ssl.conf",
      :ensure => "absent",
      :force  => true,
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default-ssl.conf/fragments').with(
      :path   => "/tmp//15-default-ssl.conf/fragments",
      :ensure => "absent",
      :force  => true,
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default-ssl.conf/fragments.concat').with(
      :path   => "/tmp//15-default-ssl.conf/fragments.concat",
      :ensure => "absent",
      :force  => true,
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default-ssl.conf/fragments.concat.out').with(
      :path   => "/tmp//15-default-ssl.conf/fragments.concat.out",
      :ensure => "absent",
      :force  => true,
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/etc/apache2/sites-available/15-default-ssl.conf').with(
      :path   => "/etc/apache2/sites-available/15-default-ssl.conf",
      :ensure => "absent",
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_exec('concat_15-default-ssl.conf').with(
      :command => "true",
      :alias   => "concat_/tmp//15-default-ssl.conf",
      :unless  => "true",
      :path    => "/bin:/usr/bin",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default-ssl.conf/fragments/0_default-ssl-apache-header').with(
      :path    => "/tmp//15-default-ssl.conf/fragments/0_default-ssl-apache-header",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "# ************************************\n# Vhost template in module puppetlabs-apache\n# Managed by Puppet\n# ************************************\n\n<VirtualHost *:443>\n  ServerName default-ssl\n  ServerAdmin root@localhost\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-ssl-apache-header",
      :notify  => Exec[concat_15-default-ssl.conf]{:command=>"concat_15-default-ssl.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default-ssl.conf/fragments/10_default-ssl-docroot').with(
      :path    => "/tmp//15-default-ssl.conf/fragments/10_default-ssl-docroot",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "\n  ## Vhost docroot\n  DocumentRoot \"/var/www\"\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-ssl-docroot",
      :notify  => Exec[concat_15-default-ssl.conf]{:command=>"concat_15-default-ssl.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default-ssl.conf/fragments/60_default-ssl-directories').with(
      :path    => "/tmp//15-default-ssl.conf/fragments/60_default-ssl-directories",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "\n  ## Directories, there should at least be a declaration for /var/www\n\n  <Directory \"/var/www\">\n    Options Indexes FollowSymLinks MultiViews\n    AllowOverride None\n    Require all granted\n  </Directory>\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-ssl-directories",
      :notify  => Exec[concat_15-default-ssl.conf]{:command=>"concat_15-default-ssl.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default-ssl.conf/fragments/80_default-ssl-logging').with(
      :path    => "/tmp//15-default-ssl.conf/fragments/80_default-ssl-logging",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "\n  ## Logging\n  ErrorLog \"/var/log/apache2/default-ssl_error_ssl.log\"\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-ssl-logging",
      :notify  => Exec[concat_15-default-ssl.conf]{:command=>"concat_15-default-ssl.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default-ssl.conf/fragments/90_default-ssl-serversignature').with(
      :path    => "/tmp//15-default-ssl.conf/fragments/90_default-ssl-serversignature",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "  ServerSignature Off\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-ssl-serversignature",
      :notify  => Exec[concat_15-default-ssl.conf]{:command=>"concat_15-default-ssl.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default-ssl.conf/fragments/100_default-ssl-access_log').with(
      :path    => "/tmp//15-default-ssl.conf/fragments/100_default-ssl-access_log",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "  CustomLog \"/var/log/apache2/ssl_access.log\" combined \n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-ssl-access_log",
      :notify  => Exec[concat_15-default-ssl.conf]{:command=>"concat_15-default-ssl.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default-ssl.conf/fragments/180_default-ssl-scriptalias').with(
      :path    => "/tmp//15-default-ssl.conf/fragments/180_default-ssl-scriptalias",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "  ## Script alias directives\n  ScriptAlias /cgi-bin \"/usr/lib/cgi-bin\"\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-ssl-scriptalias",
      :notify  => Exec[concat_15-default-ssl.conf]{:command=>"concat_15-default-ssl.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default-ssl.conf/fragments/210_default-ssl-ssl').with(
      :path    => "/tmp//15-default-ssl.conf/fragments/210_default-ssl-ssl",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "\n  ## SSL directives\n  SSLEngine on\n  SSLCertificateFile      \"/etc/ssl/certs/ssl-cert-snakeoil.pem\"\n  SSLCertificateKeyFile   \"/etc/ssl/private/ssl-cert-snakeoil.key\"\n  SSLCACertificatePath    \"/etc/ssl/certs\"\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-ssl-ssl",
      :notify  => Exec[concat_15-default-ssl.conf]{:command=>"concat_15-default-ssl.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//15-default-ssl.conf/fragments/999_default-ssl-file_footer').with(
      :path    => "/tmp//15-default-ssl.conf/fragments/999_default-ssl-file_footer",
      :ensure  => "absent",
      :mode    => "0640",
      :content => "</VirtualHost>\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_default-ssl-file_footer",
      :notify  => Exec[concat_15-default-ssl.conf]{:command=>"concat_15-default-ssl.conf"},
    )
  end

  it do
    expect(subject).to contain_concat__fragment('Listen 80').with(
      :name    => "Listen 80",
      :ensure  => "present",
      :target  => "/etc/apache2/ports.conf",
      :content => "Listen 80\n",
      :order   => "10",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('NameVirtualHost *:80').with(
      :name    => "NameVirtualHost *:80",
      :ensure  => "present",
      :target  => "/etc/apache2/ports.conf",
      :content => "NameVirtualHost *:80\n",
      :order   => "10",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('Listen 8888').with(
      :name    => "Listen 8888",
      :ensure  => "present",
      :target  => "/etc/apache2/ports.conf",
      :content => "Listen 8888\n",
      :order   => "10",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('NameVirtualHost *:8888').with(
      :name    => "NameVirtualHost *:8888",
      :ensure  => "present",
      :target  => "/etc/apache2/ports.conf",
      :content => "NameVirtualHost *:8888\n",
      :order   => "10",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('Listen 5000').with(
      :name    => "Listen 5000",
      :ensure  => "present",
      :target  => "/etc/apache2/ports.conf",
      :content => "Listen 5000\n",
      :order   => "10",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('NameVirtualHost *:5000').with(
      :name    => "NameVirtualHost *:5000",
      :ensure  => "present",
      :target  => "/etc/apache2/ports.conf",
      :content => "NameVirtualHost *:5000\n",
      :order   => "10",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('Listen 35357').with(
      :name    => "Listen 35357",
      :ensure  => "present",
      :target  => "/etc/apache2/ports.conf",
      :content => "Listen 35357\n",
      :order   => "10",
    )
  end

  it do
    expect(subject).to contain_concat__fragment('NameVirtualHost *:35357').with(
      :name    => "NameVirtualHost *:35357",
      :ensure  => "present",
      :target  => "/etc/apache2/ports.conf",
      :content => "NameVirtualHost *:35357\n",
      :order   => "10",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//25-apache_api_proxy.conf').with(
      :path   => "/tmp//25-apache_api_proxy.conf",
      :ensure => "directory",
      :mode   => "0750",
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//25-apache_api_proxy.conf/fragments').with(
      :path    => "/tmp//25-apache_api_proxy.conf/fragments",
      :ensure  => "directory",
      :mode    => "0750",
      :force   => true,
      :ignore  => [".svn", ".git", ".gitignore"],
      :notify  => Exec[concat_25-apache_api_proxy.conf]{:command=>"concat_25-apache_api_proxy.conf"},
      :purge   => true,
      :recurse => true,
      :backup  => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//25-apache_api_proxy.conf/fragments.concat').with(
      :path   => "/tmp//25-apache_api_proxy.conf/fragments.concat",
      :ensure => "present",
      :mode   => "0640",
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('/tmp//25-apache_api_proxy.conf/fragments.concat.out').with(
      :path   => "/tmp//25-apache_api_proxy.conf/fragments.concat.out",
      :ensure => "present",
      :mode   => "0640",
      :backup => "puppet",
    )
  end

  it do
    expect(subject).to contain_file('25-apache_api_proxy.conf').with(
      :path    => "/etc/apache2/sites-available/25-apache_api_proxy.conf",
      :ensure  => "present",
      :owner   => "root",
      :group   => "root",
      :mode    => "0644",
      :replace => true,
      :alias   => "concat_25-apache_api_proxy.conf",
      :source  => "/tmp//25-apache_api_proxy.conf/fragments.concat.out",
      :backup  => "puppet",
    )
  end

  it do
    expect(subject).to contain_exec('concat_25-apache_api_proxy.conf').with(
      :command   => "/tmp//bin/concatfragments.rb -o \"/tmp//25-apache_api_proxy.conf/fragments.concat.out\" -d \"/tmp//25-apache_api_proxy.conf\" -n",
      :alias     => "concat_/tmp//25-apache_api_proxy.conf",
      :notify    => File[25-apache_api_proxy.conf]{:path=>"25-apache_api_proxy.conf"},
      :subscribe => File[/tmp//25-apache_api_proxy.conf]{:path=>"/tmp//25-apache_api_proxy.conf"},
      :unless    => "/tmp//bin/concatfragments.rb -o \"/tmp//25-apache_api_proxy.conf/fragments.concat.out\" -d \"/tmp//25-apache_api_proxy.conf\" -n -t",
      :require   => [File[/tmp//25-apache_api_proxy.conf]{:path=>"/tmp//25-apache_api_proxy.conf"}, File[/tmp//25-apache_api_proxy.conf/fragments]{:path=>"/tmp//25-apache_api_proxy.conf/fragments"}, File[/tmp//25-apache_api_proxy.conf/fragments.concat]{:path=>"/tmp//25-apache_api_proxy.conf/fragments.concat"}],
    )
  end

  it do
    expect(subject).to contain_file('/tmp//25-apache_api_proxy.conf/fragments/0_apache_api_proxy-apache-header').with(
      :path    => "/tmp//25-apache_api_proxy.conf/fragments/0_apache_api_proxy-apache-header",
      :ensure  => "file",
      :mode    => "0640",
      :content => "# ************************************\n# Vhost template in module puppetlabs-apache\n# Managed by Puppet\n# ************************************\n\n<VirtualHost *:8888>\n  ServerName apache_api_proxy\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_apache_api_proxy-apache-header",
      :notify  => Exec[concat_25-apache_api_proxy.conf]{:command=>"concat_25-apache_api_proxy.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//25-apache_api_proxy.conf/fragments/10_apache_api_proxy-docroot').with(
      :path    => "/tmp//25-apache_api_proxy.conf/fragments/10_apache_api_proxy-docroot",
      :ensure  => "file",
      :mode    => "0640",
      :content => "\n  ## Vhost docroot\n  DocumentRoot \"/var/www/html\"\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_apache_api_proxy-docroot",
      :notify  => Exec[concat_25-apache_api_proxy.conf]{:command=>"concat_25-apache_api_proxy.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//25-apache_api_proxy.conf/fragments/60_apache_api_proxy-directories').with(
      :path    => "/tmp//25-apache_api_proxy.conf/fragments/60_apache_api_proxy-directories",
      :ensure  => "file",
      :mode    => "0640",
      :content => "\n  ## Directories, there should at least be a declaration for /var/www/html\n\n  <Directory \"/var/www/html\">\n    Options Indexes FollowSymLinks MultiViews\n    AllowOverride None\n    Require all granted\n  </Directory>\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_apache_api_proxy-directories",
      :notify  => Exec[concat_25-apache_api_proxy.conf]{:command=>"concat_25-apache_api_proxy.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//25-apache_api_proxy.conf/fragments/80_apache_api_proxy-logging').with(
      :path    => "/tmp//25-apache_api_proxy.conf/fragments/80_apache_api_proxy-logging",
      :ensure  => "file",
      :mode    => "0640",
      :content => "\n  ## Logging\n  ErrorLog \"syslog:local0\"\n  LogLevel notice\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_apache_api_proxy-logging",
      :notify  => Exec[concat_25-apache_api_proxy.conf]{:command=>"concat_25-apache_api_proxy.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//25-apache_api_proxy.conf/fragments/90_apache_api_proxy-serversignature').with(
      :path    => "/tmp//25-apache_api_proxy.conf/fragments/90_apache_api_proxy-serversignature",
      :ensure  => "file",
      :mode    => "0640",
      :content => "  ServerSignature Off\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_apache_api_proxy-serversignature",
      :notify  => Exec[concat_25-apache_api_proxy.conf]{:command=>"concat_25-apache_api_proxy.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//25-apache_api_proxy.conf/fragments/100_apache_api_proxy-access_log').with(
      :path    => "/tmp//25-apache_api_proxy.conf/fragments/100_apache_api_proxy-access_log",
      :ensure  => "file",
      :mode    => "0640",
      :content => "  CustomLog \"/var/log/apache2/apache_api_proxy_access.log\" combined \n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_apache_api_proxy-access_log",
      :notify  => Exec[concat_25-apache_api_proxy.conf]{:command=>"concat_25-apache_api_proxy.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//25-apache_api_proxy.conf/fragments/270_apache_api_proxy-custom_fragment').with(
      :path    => "/tmp//25-apache_api_proxy.conf/fragments/270_apache_api_proxy-custom_fragment",
      :ensure  => "file",
      :mode    => "0640",
      :content => "\n  ## Custom fragment\n  ProxyRequests on\n  ProxyVia On\n  AllowCONNECT 443 563 5000 8000 8003 8004 8080 8082 8386 8773 8774 8776 8777 9292 9696\n  HostnameLookups off\n  LimitRequestFieldSize 81900\n  <Proxy *>\n    Order Deny,Allow\n        Allow from 10.108.0.2\n        Deny from all\n  </Proxy>\n\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_apache_api_proxy-custom_fragment",
      :notify  => Exec[concat_25-apache_api_proxy.conf]{:command=>"concat_25-apache_api_proxy.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//25-apache_api_proxy.conf/fragments/999_apache_api_proxy-file_footer').with(
      :path    => "/tmp//25-apache_api_proxy.conf/fragments/999_apache_api_proxy-file_footer",
      :ensure  => "file",
      :mode    => "0640",
      :content => "</VirtualHost>\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_apache_api_proxy-file_footer",
      :notify  => Exec[concat_25-apache_api_proxy.conf]{:command=>"concat_25-apache_api_proxy.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//_etc_apache2_ports.conf/fragments/10_Listen 80').with(
      :path    => "/tmp//_etc_apache2_ports.conf/fragments/10_Listen 80",
      :ensure  => "file",
      :mode    => "0640",
      :content => "Listen 80\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_Listen 80",
      :notify  => Exec[concat_/etc/apache2/ports.conf]{:command=>"concat_/etc/apache2/ports.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_80').with(
      :path    => "/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_80",
      :ensure  => "file",
      :mode    => "0640",
      :content => "NameVirtualHost *:80\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_NameVirtualHost *:80",
      :notify  => Exec[concat_/etc/apache2/ports.conf]{:command=>"concat_/etc/apache2/ports.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//_etc_apache2_ports.conf/fragments/10_Listen 8888').with(
      :path    => "/tmp//_etc_apache2_ports.conf/fragments/10_Listen 8888",
      :ensure  => "file",
      :mode    => "0640",
      :content => "Listen 8888\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_Listen 8888",
      :notify  => Exec[concat_/etc/apache2/ports.conf]{:command=>"concat_/etc/apache2/ports.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_8888').with(
      :path    => "/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_8888",
      :ensure  => "file",
      :mode    => "0640",
      :content => "NameVirtualHost *:8888\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_NameVirtualHost *:8888",
      :notify  => Exec[concat_/etc/apache2/ports.conf]{:command=>"concat_/etc/apache2/ports.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//_etc_apache2_ports.conf/fragments/10_Listen 5000').with(
      :path    => "/tmp//_etc_apache2_ports.conf/fragments/10_Listen 5000",
      :ensure  => "file",
      :mode    => "0640",
      :content => "Listen 5000\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_Listen 5000",
      :notify  => Exec[concat_/etc/apache2/ports.conf]{:command=>"concat_/etc/apache2/ports.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_5000').with(
      :path    => "/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_5000",
      :ensure  => "file",
      :mode    => "0640",
      :content => "NameVirtualHost *:5000\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_NameVirtualHost *:5000",
      :notify  => Exec[concat_/etc/apache2/ports.conf]{:command=>"concat_/etc/apache2/ports.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//_etc_apache2_ports.conf/fragments/10_Listen 35357').with(
      :path    => "/tmp//_etc_apache2_ports.conf/fragments/10_Listen 35357",
      :ensure  => "file",
      :mode    => "0640",
      :content => "Listen 35357\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_Listen 35357",
      :notify  => Exec[concat_/etc/apache2/ports.conf]{:command=>"concat_/etc/apache2/ports.conf"},
    )
  end

  it do
    expect(subject).to contain_file('/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_35357').with(
      :path    => "/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_35357",
      :ensure  => "file",
      :mode    => "0640",
      :content => "NameVirtualHost *:35357\n",
      :backup  => "puppet",
      :replace => true,
      :alias   => "concat_fragment_NameVirtualHost *:35357",
      :notify  => Exec[concat_/etc/apache2/ports.conf]{:command=>"concat_/etc/apache2/ports.conf"},
    )
  end

