#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/indirector/file_bucket_file/file'
require 'puppet/util/platform'

describe Puppet::FileBucketFile::File do
  include PuppetSpec::Files

  describe "non-stubbing tests" do
    include PuppetSpec::Files

    before do
      Puppet[:bucketdir] = tmpdir('bucketdir')
    end

    def save_bucket_file(contents, path = "/who_cares")
      bucket_file = Puppet::FileBucket::File.new(contents)
      Puppet::FileBucket::File.indirection.save(bucket_file, "#{bucket_file.name}#{path}")
      bucket_file.checksum_data
    end

    describe "when servicing a save request" do
      it "should return a result whose content is empty" do
        bucket_file = Puppet::FileBucket::File.new('stuff')
        result = Puppet::FileBucket::File.indirection.save(bucket_file, "md5/c13d88cb4cb02003daedb8a84e5d272a")
        result.contents.should be_empty
      end

      it "deals with multiple processes saving at the same time", :unless => Puppet::Util::Platform.windows? do
        bucket_file = Puppet::FileBucket::File.new("contents")

        children = []
        5.times do |count|
          children << Kernel.fork do
            save_bucket_file("contents", "/testing")
            exit(0)
          end
        end
        children.each { |child| Process.wait(child) }

        paths = File.read("#{Puppet[:bucketdir]}/9/8/b/f/7/d/8/c/98bf7d8c15784f0a3d63204441e1e2aa/paths").lines.to_a
        paths.length.should == 1
        Puppet::FileBucket::File.indirection.head("#{bucket_file.checksum_type}/#{bucket_file.checksum_data}/testing").should be_true
      end

      it "fails if the contents collide with existing contents" do
        # This is the shortest known MD5 collision. See http://eprint.iacr.org/2010/643.pdf
        first_contents = [0x6165300e,0x87a79a55,0xf7c60bd0,0x34febd0b,
                          0x6503cf04,0x854f709e,0xfb0fc034,0x874c9c65,
                          0x2f94cc40,0x15a12deb,0x5c15f4a3,0x490786bb,
                          0x6d658673,0xa4341f7d,0x8fd75920,0xefd18d5a].pack("I" * 16)

        collision_contents = [0x6165300e,0x87a79a55,0xf7c60bd0,0x34febd0b,
                              0x6503cf04,0x854f749e,0xfb0fc034,0x874c9c65,
                              0x2f94cc40,0x15a12deb,0xdc15f4a3,0x490786bb,
                              0x6d658673,0xa4341f7d,0x8fd75920,0xefd18d5a].pack("I" * 16)

        save_bucket_file(first_contents, "/foo/bar")

        expect do
          save_bucket_file(collision_contents, "/foo/bar")
        end.to raise_error(Puppet::FileBucket::BucketError, /Got passed new contents/)
      end

      describe "when supplying a path" do
        it "should store the path if not already stored" do
          checksum = save_bucket_file("stuff\r\n", "/foo/bar")

          dir_path = "#{Puppet[:bucketdir]}/f/c/7/7/7/c/0/b/fc777c0bc467e1ab98b4c6915af802ec"
          contents_file = Puppet::FileSystem::File.new("#{dir_path}/contents")
          paths_file = Puppet::FileSystem::File.new("#{dir_path}/paths")
          contents_file.binread.should == "stuff\r\n"
          paths_file.read.should == "foo/bar\n"
        end

        it "should leave the paths file alone if the path is already stored" do
          checksum = save_bucket_file("stuff", "/foo/bar")

          checksum = save_bucket_file("stuff", "/foo/bar")

          dir_path = "#{Puppet[:bucketdir]}/c/1/3/d/8/8/c/b/c13d88cb4cb02003daedb8a84e5d272a"
          File.read("#{dir_path}/contents").should == "stuff"
          File.read("#{dir_path}/paths").should == "foo/bar\n"
        end

        it "should store an additional path if the new path differs from those already stored" do
          checksum = save_bucket_file("stuff", "/foo/bar")

          checksum = save_bucket_file("stuff", "/foo/baz")

          dir_path = "#{Puppet[:bucketdir]}/c/1/3/d/8/8/c/b/c13d88cb4cb02003daedb8a84e5d272a"
          File.read("#{dir_path}/contents").should == "stuff"
          File.read("#{dir_path}/paths").should == "foo/bar\nfoo/baz\n"
        end
      end

      describe "when not supplying a path" do
        it "should save the file and create an empty paths file" do
          checksum = save_bucket_file("stuff", "")

          dir_path = "#{Puppet[:bucketdir]}/c/1/3/d/8/8/c/b/c13d88cb4cb02003daedb8a84e5d272a"
          File.read("#{dir_path}/contents").should == "stuff"
          File.read("#{dir_path}/paths").should == ""
        end
      end
    end

    describe "when servicing a head/find request" do
      describe "when supplying a path" do
        it "should return false/nil if the file isn't bucketed" do
          Puppet::FileBucket::File.indirection.head("md5/0ae2ec1980410229885fe72f7b44fe55/foo/bar").should == false
          Puppet::FileBucket::File.indirection.find("md5/0ae2ec1980410229885fe72f7b44fe55/foo/bar").should == nil
        end

        it "should return false/nil if the file is bucketed but with a different path" do
          checksum = save_bucket_file("I'm the contents of a file", '/foo/bar')

          Puppet::FileBucket::File.indirection.head("md5/#{checksum}/foo/baz").should == false
          Puppet::FileBucket::File.indirection.find("md5/#{checksum}/foo/baz").should == nil
        end

        it "should return true/file if the file is already bucketed with the given path" do
          contents = "I'm the contents of a file"

          checksum = save_bucket_file(contents, '/foo/bar')

          Puppet::FileBucket::File.indirection.head("md5/#{checksum}/foo/bar").should == true
          find_result = Puppet::FileBucket::File.indirection.find("md5/#{checksum}/foo/bar")
          find_result.checksum.should == "{md5}#{checksum}"
          find_result.to_s.should == contents
        end
      end

      describe "when not supplying a path" do
        [false, true].each do |trailing_slash|
          describe "#{trailing_slash ? 'with' : 'without'} a trailing slash" do
            trailing_string = trailing_slash ? '/' : ''

            it "should return false/nil if the file isn't bucketed" do
              Puppet::FileBucket::File.indirection.head("md5/0ae2ec1980410229885fe72f7b44fe55#{trailing_string}").should == false
              Puppet::FileBucket::File.indirection.find("md5/0ae2ec1980410229885fe72f7b44fe55#{trailing_string}").should == nil
            end

            it "should return true/file if the file is already bucketed" do
              contents = "I'm the contents of a file"

              checksum = save_bucket_file(contents, '/foo/bar')

              Puppet::FileBucket::File.indirection.head("md5/#{checksum}#{trailing_string}").should == true
              find_result = Puppet::FileBucket::File.indirection.find("md5/#{checksum}#{trailing_string}")
              find_result.checksum.should == "{md5}#{checksum}"
              find_result.to_s.should == contents
            end
          end
        end
      end
    end

    describe "when diffing files", :unless => Puppet.features.microsoft_windows? do
      it "should generate an empty string if there is no diff" do
        checksum = save_bucket_file("I'm the contents of a file")
        Puppet::FileBucket::File.indirection.find("md5/#{checksum}", :diff_with => checksum).should == ''
      end

      it "should generate a proper diff if there is a diff" do
        checksum1 = save_bucket_file("foo\nbar\nbaz")
        checksum2 = save_bucket_file("foo\nbiz\nbaz")

        diff = Puppet::FileBucket::File.indirection.find("md5/#{checksum1}", :diff_with => checksum2)
        diff.should == <<HERE
2c2
< bar
---
> biz
HERE
      end

      it "should raise an exception if the hash to diff against isn't found" do
        bogus_checksum = "d1bf072d0e2c6e20e3fbd23f022089a1"
        checksum = save_bucket_file("whatever")

        expect do
          Puppet::FileBucket::File.indirection.find("md5/#{checksum}", :diff_with => bogus_checksum)
        end.to raise_error "could not find diff_with #{bogus_checksum}"
      end

      it "should return nil if the hash to diff from isn't found" do
        bogus_checksum = "d1bf072d0e2c6e20e3fbd23f022089a1"
        checksum = save_bucket_file("whatever")

        Puppet::FileBucket::File.indirection.find("md5/#{bogus_checksum}", :diff_with => checksum).should == nil
      end
    end
  end

  [true, false].each do |override_bucket_path|
    describe "when bucket path #{if override_bucket_path then 'is' else 'is not' end} overridden" do
      [true, false].each do |supply_path|
        describe "when #{supply_path ? 'supplying' : 'not supplying'} a path" do
          before :each do
            Puppet.settings.stubs(:use)
            @store = Puppet::FileBucketFile::File.new
            @contents = "my content"

            @digest = "f2bfa7fc155c4f42cb91404198dda01f"
            @digest.should == Digest::MD5.hexdigest(@contents)

            @bucket_dir = tmpdir("bucket")

            if override_bucket_path
              Puppet[:bucketdir] = "/bogus/path" # should not be used
            else
              Puppet[:bucketdir] = @bucket_dir
            end

            @dir = "#{@bucket_dir}/f/2/b/f/a/7/f/c/f2bfa7fc155c4f42cb91404198dda01f"
            @contents_path = "#{@dir}/contents"
          end

          describe "when retrieving files" do
            before :each do

              request_options = {}
              if override_bucket_path
                request_options[:bucket_path] = @bucket_dir
              end

              key = "md5/#{@digest}"
              if supply_path
                key += "/path/to/file"
              end

              @request = Puppet::Indirector::Request.new(:indirection_name, :find, key, nil, request_options)
            end

            def make_bucketed_file
              FileUtils.mkdir_p(@dir)
              File.open(@contents_path, 'w') { |f| f.write @contents }
            end

            it "should return an instance of Puppet::FileBucket::File created with the content if the file exists" do
              make_bucketed_file

              if supply_path
                @store.find(@request).should == nil
                @store.head(@request).should == false # because path didn't match
              else
                bucketfile = @store.find(@request)
                bucketfile.should be_a(Puppet::FileBucket::File)
                bucketfile.contents.should == @contents
                @store.head(@request).should == true
              end
            end

            it "should return nil if no file is found" do
              @store.find(@request).should be_nil
              @store.head(@request).should == false
            end
          end

          describe "when saving files" do
            it "should save the contents to the calculated path" do
              options = {}
              if override_bucket_path
                options[:bucket_path] = @bucket_dir
              end

              key = "md5/#{@digest}"
              if supply_path
                key += "//path/to/file"
              end

              file_instance = Puppet::FileBucket::File.new(@contents, options)
              request = Puppet::Indirector::Request.new(:indirection_name, :save, key, file_instance)

              @store.save(request)
              File.read("#{@dir}/contents").should == @contents
            end
          end
        end
      end
    end
  end
end
