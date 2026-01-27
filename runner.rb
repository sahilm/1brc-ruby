#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require_relative "./v1_1brc"

puts V1::OneBRC.compute
