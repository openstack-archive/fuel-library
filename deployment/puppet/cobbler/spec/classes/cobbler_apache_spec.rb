require "spec_helper"

describe "cobbler::apache" do

  shared_examples_for "cobbler configuration" do

    context "with default params" do

      it "configures with the default params" do

        should contain_class("apache").with(
            :server_signature => "Off",
            :trace_enable => "Off",
            :purge_configs => false,
            :default_vhost => false,
        )
        should contain_apache__vhost("cobbler non-ssl").with(
            :servername => "_default_",
            :port => 80,
            :docroot => "/var/www/html",
            :aliases => [
                {
                    "alias" => "/cobbler/boot",
                    "path" => "/var/lib/tftpboot",
                },
            ],
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
            :directories => [
                {
                    "path" => "/var/lib/tftpboot",
                    "options" => ["Indexes", "FollowSymLinks"],
                },
            ],
        )

        should contain_apache__vhost("cobbler ssl").with(
            :servername => "_default_",
            :port => 443,
            :docroot => "/var/www/html",
            :ssl => true,
            :ssl_cert => "/var/lib/fuel/keys/master/cobbler/cobbler.crt",
            :ssl_key => "/var/lib/fuel/keys/master/cobbler/cobbler.key",
            :rewrites => [
                {
                    "comment" => "Redirect root path to SSL Nailgun",
                    "rewrite_rule" => ["^/$ https://%{HTTP_HOST}:8443%{REQUEST_URI} [R=301,L]"],
                },
            ],
            :ssl_cipher => "ALL:!ADH:!EXPORT:!SSLv2:!MEDIUM:!LOW:+HIGH",
            :setenvif => ["User-Agent \".*MSIE.*\" nokeepalive ssl-unclean-shutdown downgrade-1.0 force-response-1.0"],
        )
      end
    end
  end

  context "on Debian platforms" do
    let :facts do
      @default_facts.merge(
      { :osfamily => "Debian",
        :operatingsystem => "Debian",
        :operatingsystemrelease => "7",
      })
    end

    it_configures "cobbler configuration"
  end

  context "on RedHat platforms" do
    let :facts do
      @default_facts.merge(
      { :osfamily => "RedHat",
        :operatingsystem => "RedHat",
        :operatingsystemrelease => "7.0",
      })
    end

    it_configures "cobbler configuration"
  end

end

