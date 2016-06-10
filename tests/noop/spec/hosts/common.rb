shared_examples 'compute_service_common' do

  let (:nova_compute_service_name) do
    Noop.puppet_class_include 'nova::params'
    Noop.variable 'nova::params::compute_service_name'
  end

  compute_vmware = Noop.puppet_function 'roles_include', 'compute-vmware'

  if !compute_vmware
    it do
      is_expected.not_to contain_service(nova_compute_service_name).with(:ensure => 'running')
    end
  end

end

shared_examples 'common' do
  include_examples 'compute_service_common' unless Noop.current_spec_is? 'roles/enable_compute'
end
