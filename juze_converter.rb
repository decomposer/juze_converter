#!/usr/bin/env ruby

require 'yaml'

FILES = ARGV

WORDS = YAML.load_file(File.expand_path('../words.yaml', __FILE__))

class String
  def translate!(pattern, method = nil)
    gsub!(pattern) do |match|
      if WORDS.key?(match.downcase)
        method ? WORDS[match.downcase].send(method) : WORDS[match.downcase].downcase
      else
        match
      end
    end
  end
end

FILES.each do |file|
  source = File.read(file)
  begin
    source.translate!(/[a-z]{2,}/)
    source.translate!(/[A-Z]{2,}/, :upcase)
    source.translate!(/[A-Z][a-z]+/, :capitalize)
    File.write(file, source)
    puts "Converted: #{file}"
  rescue => ex
    warn "Couldn't convert: #{file}, #{ex}"
  end
end
