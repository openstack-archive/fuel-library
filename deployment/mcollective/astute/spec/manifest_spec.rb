require "rspec"
require "manifest"
require "yaml"


describe "My behaviour" do

  it "should do something" do
    print Template.p_(
        {
            :asdf => {:asdf => ['$fdsa', 1, true],
                      :fda1 => [],
                      :ddd => {},
            },
        })
    #To change this template use File | Settings | File Templates.
    true.should == false
  end

  it "fgsshould do somdfaething" do
    puts YAML.dump({:a => [{:c=>'d', :g=>'55'}, {:r=> %w(d c), :g=>'55'}]})

  end

  it "fgsshould do something" do
    config = ConfigYaml.load_file('C:\work\fuel\deployment\mcollective\astute\samples\config.yaml')
    config.internal_virtual_ip()
    config.public_virtual_ip()
    config.floating_range()
    config.fixed_range()
    config.mirror_type()
    config.template()
    config.quantums()
    config.quantum()
    config.swift_proxies()
    config.controllers()
    config.loopback()
    config.cinder()
    config.cinder_nodes()
    config.use_syslog()
    config.swift()
    config.default_gateway()
    config.nagios_master()
    config.public_interface()
    config.internal_interface()
    config.private_interface()
    config.nv_physical_volumes()
    config.external_ip_info()
    config.dns_nameservers()

    ConfigYaml.load_file('C:\work\fuel\deployment\mcollective\astute\samples\config.yaml')
    template = Template.new('C:\work\fuel\deployment\mcollective\astute\templates\site_openstack_full.pp')
    print Manifest.prepare_manifest(template, config)
  end
end
