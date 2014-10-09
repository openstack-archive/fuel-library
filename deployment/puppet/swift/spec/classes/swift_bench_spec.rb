require 'spec_helper'

describe 'swift::bench' do

  let :default_params do
    { :auth_url          => 'http://localhost:8080/auth/v1.0',
      :swift_user        => 'test:tester',
      :swift_key         => 'testing',
      :auth_version      => '1.0',
      :log_level         => 'INFO',
      :test_timeout      => '10',
      :put_concurrency   => '10',
      :get_concurrency   => '10',
      :del_concurrency   => '10',
      :lower_object_size => '10',
      :upper_object_size => '10',
      :object_size       => '1',
      :num_objects       => '1000',
      :num_gets          => '10000',
      :num_containers    => '20',
      :delete            => 'yes' }
  end

  let :pre_condition do
    "class { 'swift': swift_hash_suffix => 'string' }"
  end

  let :facts do
    { :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian' }
  end

  let :params do
    {}
  end

  shared_examples 'swift::bench' do
    let (:p) { default_params.merge!(params) }

    it 'depends on swift package' do
      should contain_package('swift').with_before(/Swift_bench_config\[.+\]/)
    end

    it 'configures swift-bench.conf' do
      should contain_swift_bench_config(
        'bench/auth').with_value(p[:auth_url])
      should contain_swift_bench_config(
        'bench/user').with_value(p[:swift_user])
      should contain_swift_bench_config(
        'bench/key').with_value(p[:swift_key])
      should contain_swift_bench_config(
        'bench/auth_version').with_value(p[:auth_version])
      should contain_swift_bench_config(
        'bench/log-level').with_value(p[:log_level])
      should contain_swift_bench_config(
        'bench/timeout').with_value(p[:test_timeout])
      should contain_swift_bench_config(
        'bench/put_concurrency').with_value(p[:put_concurrency])
      should contain_swift_bench_config(
        'bench/get_concurrency').with_value(p[:get_concurrency])
      should contain_swift_bench_config(
        'bench/get_concurrency').with_value(p[:get_concurrency])
      should contain_swift_bench_config(
        'bench/lower_object_size').with_value(p[:lower_object_size])
      should contain_swift_bench_config(
        'bench/upper_object_size').with_value(p[:upper_object_size])
      should contain_swift_bench_config(
        'bench/object_size').with_value(p[:object_size])
      should contain_swift_bench_config(
        'bench/num_objects').with_value(p[:num_objects])
      should contain_swift_bench_config(
        'bench/num_gets').with_value(p[:num_gets])
      should contain_swift_bench_config(
        'bench/num_containers').with_value(p[:num_containers])
      should contain_swift_bench_config(
        'bench/delete').with_value(p[:delete])
    end
  end

  describe 'with defaults' do
    include_examples 'swift::bench'
  end

  describe 'when overridding' do
    before do
      params.merge!(
        :auth_url        => 'http://127.0.0.1:8080/auth/v1.0',
        :swift_user      => 'admin:admin',
        :swift_key       => 'admin',
        :put_concurrency => '20'
      )
    end

    include_examples 'swift::bench'
  end
end
