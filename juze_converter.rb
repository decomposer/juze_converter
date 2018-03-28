require 'yaml'

FILES = ARGV

WORDS = YAML.load_file('words.yaml')

class String
  def translate!(pattern, method = nil)
    gsub!(/([\s_]*)(#{pattern})/) do
      space = Regexp.last_match[1]
      word = Regexp.last_match[2]
      if WORDS.key?(word.downcase)
        space + (method ? WORDS[word.downcase].send(method) : WORDS[word.downcase].downcase)
      else
        space + word
      end
    end
  end
end

FILES.each do |file|
  source = File.read(file)
  source.translate!('[a-z]{2,}')
  source.translate!('[A-Z]{2,}', :upcase)
  source.translate!('[A-Z][a-z]+', :capitalize)
  puts source
end
