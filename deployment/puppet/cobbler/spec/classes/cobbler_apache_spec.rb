require "spec_helper"

describe "cobbler::apache" do

  shared_examples_for "cobbler configuration" do

    context "with default params" do
      let(:aliases) do
        if Puppet.version.to_f >= 4.0
          [
              {
                  "alias" => "/cobbler/boot",
                  "path" => "/var/lib/tftpboot",
              }
          ]
        else
          [
              ["alias", "/cobbler/boot"],
              ["path", "/var/lib/tftpboot"],
          ]
        end
      end

      let(:directories) do
        if Puppet.version.to_f >= 4.0
          [
              {
                  "path" => "/var/lib/tftpboot",
                  "options" => ["Indexes", "FollowSymLinks"],
              },
          ]
        else
          [
              ["path", "/var/lib/tftpboot"],
              ["options", ["Indexes", "FollowSymLinks"]],
          ]
        end
      end

      let(:ssl_rewrites) do
        if Puppet.version.to_f >= 4.0
          [
              {
                  "comment" => "Redirect root path to SSL Nailgun",
                  "rewrite_rule" => ["^/$ https://%{HTTP_HOST}:8443%{REQUEST_URI} [R=301,L]"],
              },
          ]
          else
          [
              ["comment", "Redirect root path to SSL Nailgun"],
              ["rewrite_rule", ["^/$ https://%{HTTP_HOST}:8443%{REQUEST_URI} [R=301,L]"]]
          ]
        end
      end

      it "ensures httpd confdir for ports-configs" do
        is_expected.to contain_file('/etc/httpd/conf.ports.d/').with(
          :ensure => 'directory',
        )
      end

      it "configures 'apache' class" do
        is_expected.to contain_class("apache").with(
            :server_signature => "Off",
            :trace_enable     => "Off",
            :purge_configs    => false,
            :purge_vhost_dir  => false,
            :default_vhost    => false,
            :conf_template    => 'fuel/httpd.conf.erb',
            :ports_file       => '/etc/httpd/conf.ports.d/cobbler.conf',
        )
      end

      it "creates 'cobbler non-ssl' vhost" do
        is_expected.to contain_apache__vhost("cobbler non-ssl").with(
            :servername => "_default_",
            :port => 80,
            :docroot => "/var/www/html",
            :aliases => aliases,
            :rewrites => [
                {
                    "comment" => "Redirect root path to SSL Nailgun",
                    "rewrite_cond" => ["%{HTTPS} off"],
                    "rewrite_rule" => ["^/$ https://%{HTTP_HOST}:8443%{REQUEST_URI} [R=301,L]"]
                },
                {
                    "comment" => "Redirect other non-cobbler path to Nailgun",
                    "rewrite_cond" => ["%{HTTPS} off", "%{REQUEST_URI} !^/(cblr|cobbler)"],
                    "rewrite_rule" => ["(.*) http://%{HTTP_HOST}:8000%{REQUEST_URI} [R=301,L]"]
                },
            ],
            :directories => directories,
        )
      end

      it "creates 'cobbler ssl' vhost" do
        is_expected.to contain_apache__vhost("cobbler ssl").with(
            :servername => "_default_",
            :port => 443,
            :docroot => "/var/www/html",
            :ssl => true,
            :ssl_cert => "/var/lib/fuel/keys/master/cobbler/cobbler.crt",
            :ssl_key => "/var/lib/fuel/keys/master/cobbler/cobbler.key",
            :rewrites => ssl_rewrites,
            :ssl_cipher => "ALL:!ADH:!EXPORT:!SSLv2:!MEDIUM:!LOW:+HIGH",
            :setenvif => ["User-Agent \".*MSIE.*\" nokeepalive ssl-unclean-shutdown downgrade-1.0 force-response-1.0"],
        )
      end

    end

  end

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it_configures "cobbler configuration"
    end
  end

end

