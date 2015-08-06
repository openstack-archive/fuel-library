require 'spec_helper'
require 'puppet/module_tool'

describe Puppet::ModuleTool::Tar::Mini, :if => (Puppet.features.minitar? and Puppet.features.zlib?) do
  let(:sourcefile) { '/the/module.tar.gz' }
  let(:destdir)    { File.expand_path '/the/dest/dir' }
  let(:sourcedir)  { '/the/src/dir' }
  let(:destfile)   { '/the/dest/file.tar.gz' }
  let(:minitar)    { described_class.new('nginx') }

  it "unpacks a tar file" do
    unpacks_the_entry(:file_start, 'thefile')

    minitar.unpack(sourcefile, destdir, 'uid')
  end

  it "does not allow an absolute path" do
    unpacks_the_entry(:file_start, '/thefile')

    expect {
      minitar.unpack(sourcefile, destdir, 'uid')
    }.to raise_error(Puppet::ModuleTool::Errors::InvalidPathInPackageError,
                     "Attempt to install file into \"/thefile\" under \"#{destdir}\"")
  end

  it "does not allow a file to be written outside the destination directory" do
    unpacks_the_entry(:file_start, '../../thefile')

    expect {
      minitar.unpack(sourcefile, destdir, 'uid')
    }.to raise_error(Puppet::ModuleTool::Errors::InvalidPathInPackageError,
                     "Attempt to install file into \"#{File.expand_path('/the/thefile')}\" under \"#{destdir}\"")
  end

  it "does not allow a directory to be written outside the destination directory" do
    unpacks_the_entry(:dir, '../../thedir')

    expect {
      minitar.unpack(sourcefile, destdir, 'uid')
    }.to raise_error(Puppet::ModuleTool::Errors::InvalidPathInPackageError,
                     "Attempt to install file into \"#{File.expand_path('/the/thedir')}\" under \"#{destdir}\"")
  end

  it "packs a tar file" do
    writer = mock('GzipWriter')

    Zlib::GzipWriter.expects(:open).with(destfile).yields(writer)
    Archive::Tar::Minitar.expects(:pack).with(sourcedir, writer)

    minitar.pack(sourcedir, destfile)
  end

  def unpacks_the_entry(type, name)
    reader = mock('GzipReader')

    Zlib::GzipReader.expects(:open).with(sourcefile).yields(reader)
    Archive::Tar::Minitar.expects(:unpack).with(reader, destdir).yields(type, name, nil)
  end
end
