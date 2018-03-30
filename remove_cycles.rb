#!/usr/bin/env ruby

require 'yaml'
require 'set'
require 'highline/import'

FILE = ARGV.shift
WORDS = File.read('/usr/share/dict/words').split("\n").to_set
DICTIONARY = YAML.load_file(FILE)

decided = Set.new

DICTIONARY.select! do |uk, us|
  if uk == us
    false
  elsif decided.include?(uk)
    false
  elsif decided.include?(us)
    true
  elsif DICTIONARY[DICTIONARY[uk]] == uk
    if WORDS.include?(uk) || WORDS.include?(uk + 's') || WORDS.include?(uk.sub(/s$/, ''))
      false
    elsif WORDS.include?(us) || WORDS.include?(us + 's') || WORDS.include?(uk.sub(/s$/, ''))
      true
    else
      v = HighLine.agree("\"#{uk}\" -> \"#{us}\"?")
      decided.add(v ? uk : us)
      v
    end
  else
    true
  end
end

File.write(FILE, DICTIONARY.to_yaml)
