require 'yaml'
require 'pp'

FILES = ARGV

WORDS = YAML.load_file('words.yaml')

FILES.each do |file|
  source = File.read(file)
  WORDS.each do |original, translated|
    next unless original
    source.gsub!(/([\s_]*)([a-zA-Z])(([a-z]|[A-Z])*)/) do
      space = Regexp.last_match[1]
      word = Regexp.last_match[2] + Regexp.last_match[3]

      replacement = WORDS[word.downcase]

      if replacement
        if word =~ /^[A-Z]+$/
          replacement = replacement.upcase
        elsif word =~ /^[A-Z]/
          replacement = replacement.capitalize
        end
        space + replacement
      else
        space + word
      end
    end
  end

  puts source
end
