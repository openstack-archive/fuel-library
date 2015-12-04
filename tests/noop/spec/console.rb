#!/usr/bin/env ruby

lib_dir = File.join File.dirname(__FILE__), '..', 'spec', 'lib'
lib_dir = File.absolute_path File.expand_path lib_dir
$LOAD_PATH << lib_dir

require 'noop'
require 'noop/cli'
require 'pry'

Noop.pry
