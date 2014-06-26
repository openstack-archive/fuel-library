require 'spec_helper'
describe 'rsync::get', :type => :define do
  let :title do
    'foobar'
  end

  let :common_params do
    {
      :source => 'example.com'
    }
  end

  describe "when using default class paramaters" do
    let :params do
      common_params
    end

    it {
      should contain_exec("rsync foobar").with({
        'command' => 'rsync -q -a example.com foobar',
        'onlyif'  => "test `rsync --dry-run --itemize-changes -a example.com foobar | wc -l` -gt 0",
        'timeout' => '900',
        'user'    => 'root'
      })
    }
  end

  describe "when setting the execuser" do
    let :params do
      common_params.merge( { :execuser => 'username' } )
    end

    it{ should contain_exec("rsync foobar").with({ 'user' => 'username' }) }
  end

  describe "when setting the timeout" do
    let :params do
      common_params.merge( { :timeout => '200' } )
    end

    it {
      should contain_exec("rsync foobar").with({ 'timeout' => '200' })
    }
  end

  describe "when setting a user but not a keyfile" do
    let :params do
      common_params.merge({ :user => 'mr_baz' })
    end

    it {
      should contain_exec("rsync foobar").with({
        'command' => 'rsync -q -a -e \'ssh -i /home/mr_baz/.ssh/id_rsa -l mr_baz\' mr_baz@example.com foobar',
        'onlyif'  => "test `rsync --dry-run --itemize-changes -a -e \'ssh -i /home/mr_baz/.ssh/id_rsa -l mr_baz\' mr_baz@example.com foobar | wc -l` -gt 0",
      })
    }
  end

  describe "when setting a keyfile but not a user" do
    let :params do
      common_params.merge( { :keyfile => "/path/to/keyfile" } )
    end

    it {
      should contain_exec("rsync foobar").with({
        'command' => 'rsync -q -a example.com foobar',
        'onlyif'  => "test `rsync --dry-run --itemize-changes -a example.com foobar | wc -l` -gt 0",
      })
    }
  end

  describe "when setting a user and a keyfile" do
    let :params do
      common_params.merge({
        :user    => 'mr_baz',
        :keyfile => '/path/to/keyfile'
      })
    end

    it {
      should contain_exec("rsync foobar").with({
        'command' => 'rsync -q -a -e \'ssh -i /path/to/keyfile -l mr_baz\' mr_baz@example.com foobar',
        'onlyif'  => "test `rsync --dry-run --itemize-changes -a -e \'ssh -i /path/to/keyfile -l mr_baz\' mr_baz@example.com foobar | wc -l` -gt 0",
       })
    }
  end

  describe "when setting an exclude path" do
    let :params do
      common_params.merge({ :exclude => '/path/to/exclude/' })
    end

    it {
      should contain_exec("rsync foobar").with({
        'command' => 'rsync -q -a --exclude=/path/to/exclude/ example.com foobar',
        'onlyif'  => "test `rsync --dry-run --itemize-changes -a --exclude=/path/to/exclude/ example.com foobar | wc -l` -gt 0",
       })
    }
  end

  describe "when setting an include path" do
    let :params do
      common_params.merge({ :include => '/path/to/include/' })
    end

    it {
      should contain_exec("rsync foobar").with({
        'command' => 'rsync -q -a --include=/path/to/include/ example.com foobar',
        'onlyif'  => "test `rsync --dry-run --itemize-changes -a --include=/path/to/include/ example.com foobar | wc -l` -gt 0",
       })
    }
  end

  describe "when enabling purge" do
    let :params do
      common_params.merge({ :purge => true })
    end

    it {
      should contain_exec("rsync foobar").with({
        'command' => 'rsync -q -a --delete example.com foobar',
        'onlyif'  => "test `rsync --dry-run --itemize-changes -a --delete example.com foobar | wc -l` -gt 0"
       })
    }
  end

  describe "when enabling recursive" do
    let :params do
      common_params.merge({ :recursive => true })
    end

    it {
      should contain_exec("rsync foobar").with({
        'command' => 'rsync -q -a -r example.com foobar',
        'onlyif'  => "test `rsync --dry-run --itemize-changes -a -r example.com foobar | wc -l` -gt 0"
       })
    }
  end

  describe "when enabling links" do
    let :params do
      common_params.merge({ :links => true })
    end

    it {
      should contain_exec("rsync foobar").with({
        'command' => 'rsync -q -a --links example.com foobar',
        'onlyif'  => "test `rsync --dry-run --itemize-changes -a --links example.com foobar | wc -l` -gt 0"
       })
    }
  end

  describe "when enabling hardlinks" do
    let :params do
      common_params.merge({ :hardlinks => true })
    end

    it {
      should contain_exec("rsync foobar").with({
        'command' => 'rsync -q -a --hard-links example.com foobar',
        'onlyif'  => "test `rsync --dry-run --itemize-changes -a --hard-links example.com foobar | wc -l` -gt 0"
       })
    }
  end

  describe "when enabling copylinks" do
    let :params do
      common_params.merge({ :copylinks => true })
    end

    it {
      should contain_exec("rsync foobar").with({
        'command' => 'rsync -q -a --copy-links example.com foobar',
        'onlyif'  => "test `rsync --dry-run --itemize-changes -a --copy-links example.com foobar | wc -l` -gt 0"
       })
    }
  end

  describe "when enabling times" do
    let :params do
      common_params.merge({ :times => true })
    end

    it {
      should contain_exec("rsync foobar").with({
        'command' => 'rsync -q -a --times example.com foobar',
        'onlyif'  => "test `rsync --dry-run --itemize-changes -a --times example.com foobar | wc -l` -gt 0"
       })
    }
  end

  describe "when setting a custom path" do
    let :params do
      common_params.merge({ :path => 'barfoo' })
    end

    it {
      should contain_exec("rsync foobar").with({
        'command' => 'rsync -q -a example.com barfoo',
        'onlyif'  => "test `rsync --dry-run --itemize-changes -a example.com barfoo | wc -l` -gt 0"
       })
    }
  end
end
