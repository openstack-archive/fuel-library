require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master2/host.pp'

describe manifest do

  shared_examples 'catalog' do

    config_path = '/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml'
    bootstrap_cli_package = 'fuel-bootstrap-cli'

    bootstrap_hash = {
      "flavor" => "ubuntu",
      "http_proxy" => "",
      "https_proxy" => "",
      "repos" =>
      [
       {
         "name" => "ubuntu",
         "priority" => nil,
         "section" => "main universe multiverse",
         "suite" => "trusty",
         "type" => "deb",
         "uri" => "http://archive.ubuntu.com/ubuntu"
       },
       {
         "name" => "mos",
         "priority" => 1050,
         "section" => "main restricted",
         "suite" => "mos9.0",
         "type" => "deb",
         "uri" => "http://mirror.fuel-infra.org/mos-repos/ubuntu/9.0",
       }
      ]
    }

    additional_settings_hash =  {
      'direct_repo_addresses' => ['10.109.0.2', '127.0.0.1']
    }

    it 'should declare fuel::bootstrap_cli class with proper arguments' do
      should contain_class('fuel::bootstrap_cli').with(
        'settings'              => bootstrap_hash,
        'direct_repo_addresses' => additional_settings_hash['direct_repo_addresses'],
        'bootstrap_cli_package' => bootstrap_cli_package,
        'config_path'           => config_path,
      )
    end

    it "should install fuel-bootstrap-cli package" do
      should contain_package(bootstrap_cli_package).with(
        'ensure' => 'present',
      )
    end

    custom_settings = bootstrap_hash.merge(additional_settings_hash)

    it 'should declare merge_yaml_settings' do
      should contain_merge_yaml_settings(config_path).with({
        'sample_settings'   => config_path,
        'override_settings' => custom_settings,
        'ensure'            => 'present',
        'require'           => "Package[#{bootstrap_cli_package}]",
      })
    end

    context 'running on centos 7' do
      let(:facts) do
        Noop.centos_facts.merge({
          :operatingsystemmajrelease => '7'
        })
      end
    end #context

    it 'should remove ssh_config sendenv defaults' do
      should contain_augeas('Remove ssh_config SendEnv defaults').with(
        :lens    => 'ssh.lns',
        :incl    => '/etc/ssh/ssh_config',
        :changes => [ 'rm */SendEnv',
                      'rm SendEnv',
        ],
      )
    end

    it 'should configure login.defs for password aging and length settings' do
      should contain_augeas('Password aging and length settings').with(
        :lens    => 'login_defs.lns',
        :incl    => '/etc/login.defs',
        :changes => [
          'set PASS_MAX_DAYS 365',
          'set PASS_MIN_DAYS 2',
          'set PASS_MIN_LEN 8',
          'set PASS_WARN_AGE 30',
        ],
      )
    end

    it 'should configure system-auth password complexity' do
      should contain_augeas('Password complexity').with(
        :lens    => 'pam.lns',
        :incl    => '/etc/pam.d/system-auth',
        :changes => [
          "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/control requisite",
          "rm *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument",
          "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument[1] try_first_pass",
          "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument[2] retry=3",
          "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument[3] dcredit=-1",
          "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument[4] ucredit=-1",
          "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument[5] ocredit=-1",
          "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument[6] lcredit=-1",
        ],
        :onlyif => "match *[type='password'][control='requisite'][module='pam_pwquality.so' or module='pam_cracklib.so'] size > 0",
      )
    end

    it 'sould configure ssh client to use only v2 protocol' do
      should contain_augeas('Enable only SSHv2 connections from the master node').with(
        :lens    => 'ssh.lns',
        :incl    => '/etc/ssh/ssh_config',
        :changes => [
          'rm Protocol',
          'ins Protocol before Host[1]',
          'set Protocol 2',
        ],
      )
    end

  end #shared_examples

  test_centos manifest
end
