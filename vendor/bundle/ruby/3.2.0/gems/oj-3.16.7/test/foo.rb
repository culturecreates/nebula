#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'
$LOAD_PATH << File.join(__dir__, '../lib')
$LOAD_PATH << File.join(__dir__, '../ext')

require 'oj'

reader, writer = IO.pipe

thread =
  Thread.new do
    5.times do |id|
      Oj.to_stream(writer, { "id" => id })
      sleep(1)
    end

    writer.close
  end

p = Oj::Parser.new(:usual)
p.load(reader) { |data| puts "#{Time.now} -- ID: #{data["id"]}" }

reader.close
thread.join
