#! /usr/bin/env ruby

if ARGV.empty? || ((ARGV.length == 1) && %w(--help -h).include(ARGV.first))
  $stderr.puts 'Usage:'
  $stderr.puts "  #{$0}"
  $stderr.puts "  #{$0} PROCESSPATTERN"
  $stderr.puts "  #{$0} PROCESSPATTERN1 PROCESSPATTERN2"
  exit 1
end

IO.popen do |stdout|
  $stdout.write stdout.read
end
