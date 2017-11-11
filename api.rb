#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift('./lib')

require 'bundler/setup'
Bundler.require
Bundler.require(:development)

# mimic_awesome_print
alias p_ p
undef p
alias p ap

require 'yaml'
require 'n0core'

if ARGV.size != 1
  puts "#{$PROGRAM_NAME} [spec.yaml]"
  exit
end

file_path = ARGV.shift.strip

hash = YAML.load_file(file_path)

p spec0 = N0core::Spec0.new(hash)

p ' - - - - -'

# p spec0.templates

# p spec1 = spec0.to_spec1
puts spec0.to_spec1.to_yaml
