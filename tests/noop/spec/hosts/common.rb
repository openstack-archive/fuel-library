shared_examples 'compute_service_common' do

  let (:nova_compute_service_name) do
    Noop.puppet_class_include 'nova::params'
    Noop.variable 'nova::params::compute_service_name'
  end

  it do
    is_expected.not_to contain_service(nova_compute_service_name).with(:ensure => 'running')
  end

end

shared_examples 'common' do
  include_examples 'compute_service_common' unless Noop.current_spec_is? 'roles/enable_compute' or Noop.current_spec_is? 'vmware/compute-vmware'
end
