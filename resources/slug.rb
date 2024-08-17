#!/usr/bin/env ruby

class Slug

  attr_reader :in_stream, :out_stream

  def initialize(in_stream:, out_stream:)
    @in_stream, @out_stream = in_stream, out_stream
  end

  def stream!
    lines = 0

    in_stream.each do |line|
      slug = line.
        strip.
        gsub(/['"‘’“”]/, '').                # No quotation marks
        gsub(/[^[:alpha:][:digit:]]+/, '-'). # Nonalphanumerics to hyphen
        gsub(/^-+/, '').                     # No leading hyphens
        gsub(/-+$/, '').                     # No trailing hyphens
        downcase
      out_stream.puts slug
      lines += 1
    end
  end

end

def bold(text)
  "\e[1m#{text}\e[22m"
end

def underline(text)
  "\e[4m#{text}\e[24m"
end

if File.expand_path($0) == File.expand_path(__FILE__)
  case ARGV.first
    when '--help', '-h'
      script = File.basename($0)
      puts "Makes slugs out of lines of text.\n"
      puts 'Usage:'
      puts "       #{bold(script)} #{underline('A LINE OF TEXT TO BE “SLUGGED”')}"
      puts "       #{bold(script)} #{underline('FILENAME')}"
      puts "       #{bold(script)} <#{underline('FILENAME')}"
      exit 0
  end

  in_stream = if ((ARGV.length == 1) && File.exist?(ARGV.first))
    ARGF
  else
    [ARGV.join(' ')]
  end
  Slug.new(in_stream: in_stream, out_stream: STDOUT).stream!
end
