require 'spec_helper'
require 'noop/config'

describe Noop::Config do
  let (:repo_root) do
    File.absolute_path File.join File.dirname(__FILE__), '..', '..', '..', '..'
  end

  context 'base' do
    it 'dir_path_config' do
      expect(subject.dir_path_config).to be_a Pathname
      expect(subject.dir_path_config.to_s).to eq "#{repo_root}/tests/noop/lib/noop/config"
    end

    it 'dir_path_task_root' do
      expect(subject.dir_path_task_root).to be_a Pathname
      expect(subject.dir_path_task_root.to_s).to eq "#{repo_root}/tests/noop"
    end

    it 'dir_path_repo_root' do
      expect(subject.dir_path_repo_root).to be_a Pathname
      expect(subject.dir_path_repo_root.to_s).to eq "#{repo_root}"
    end

    it 'dir_path_task_spec' do
      expect(subject.dir_path_task_spec).to be_a Pathname
      expect(subject.dir_path_task_spec.to_s).to eq "#{repo_root}/tests/noop/spec/hosts"
    end

    it 'dir_path_modules_local' do
      expect(subject.dir_path_modules_local).to be_a Pathname
      expect(subject.dir_path_modules_local.to_s).to eq "#{repo_root}/deployment/puppet"
    end

    it 'dir_path_tasks_local' do
      expect(subject.dir_path_tasks_local).to be_a Pathname
      expect(subject.dir_path_tasks_local.to_s).to eq "#{repo_root}/deployment/puppet/osnailyfacter/modular"
    end

    it 'dir_path_modules_node' do
      expect(subject.dir_path_modules_node).to be_a Pathname
      expect(subject.dir_path_modules_node.to_s).to eq "/etc/puppet/modules"
    end

    it 'dir_path_tasks_node' do
      expect(subject.dir_path_tasks_node).to be_a Pathname
      expect(subject.dir_path_tasks_node.to_s).to eq "/etc/puppet/modules/osnailyfacter/modular"
    end

    it 'dir_path_deployment' do
      expect(subject.dir_path_deployment).to be_a Pathname
      expect(subject.dir_path_deployment.to_s).to eq "#{repo_root}/deployment"
    end

    it 'dir_path_workspace' do
      expect(subject.dir_path_workspace).to be_a Pathname
      expect(subject.dir_path_workspace.to_s).to eq "/tmp/noop"
    end
  end

  context 'hiera' do
    it 'dir_name_hiera' do
      expect(subject.dir_name_hiera).to be_a Pathname
      expect(subject.dir_name_hiera.to_s).to eq "hiera"
    end

    it 'dir_path_hiera' do
      expect(subject.dir_path_hiera).to be_a Pathname
      expect(subject.dir_path_hiera.to_s).to eq "#{repo_root}/tests/noop/hiera"
    end

    it 'dir_name_hiera_override' do
      expect(subject.dir_name_hiera_override).to be_a Pathname
      expect(subject.dir_name_hiera_override.to_s).to eq "override"
    end

    it 'dir_path_hiera_override' do
      expect(subject.dir_path_hiera_override).to be_a Pathname
      expect(subject.dir_path_hiera_override.to_s).to eq "#{repo_root}/tests/noop/hiera/override"
    end
  end

  context 'facts' do
    it 'dir_name_facts' do
      expect(subject.dir_name_facts).to be_a Pathname
      expect(subject.dir_name_facts.to_s).to eq "facts"
    end

    it 'dir_path_facts' do
      expect(subject.dir_path_facts).to be_a Pathname
      expect(subject.dir_path_facts.to_s).to eq "#{repo_root}/tests/noop/facts"
    end

    it 'dir_name_facts_override' do
      expect(subject.dir_name_facts_override).to be_a Pathname
      expect(subject.dir_name_facts_override.to_s).to eq "facts"
    end

    it 'dir_path_facts_override' do
      expect(subject.dir_path_facts_override).to be_a Pathname
      expect(subject.dir_path_facts_override.to_s).to eq "#{repo_root}/tests/noop/facts"
    end
  end

  context 'globals' do
    it 'dir_name_globals' do
      expect(subject.dir_name_globals).to be_a Pathname
      expect(subject.dir_name_globals.to_s).to eq "globals"
    end

    it 'dir_path_globals' do
      expect(subject.dir_path_globals).to be_a Pathname
      expect(subject.dir_path_globals.to_s).to eq "#{repo_root}/tests/noop/hiera/globals"
    end
  end

end
