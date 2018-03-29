#!/usr/bin/env ruby

# git reset --hard && find . -type f -exec grep -Iq . {} \; -and -print0 | time xargs -0 ../JuzeConverter/juze_converter.rb

require 'yaml'
require 'set'

FILES = ARGV

WORDS = YAML.load_file(File.expand_path('../words.yaml', __FILE__))

BLACKLIST = YAML.load_file(File.expand_path('../blacklist.yaml', __FILE__))
BLACKLIST.each { |b| WORDS.delete(b) }

TRANSLATED = Set.new

class String
  def translate!(pattern, method = nil)
    gsub!(/(^|[_\W])(#{pattern})/) do
      space = Regexp.last_match[1]
      word = Regexp.last_match[2]
      if WORDS.key?(word.downcase)
        TRANSLATED.add(word.downcase)
        space + (method ? WORDS[word.downcase].send(method) : WORDS[word.downcase].downcase)
      else
        space + word
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

puts TRANSLATED.to_a.sort.join("\n")
