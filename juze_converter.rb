#!/usr/bin/env ruby

require 'open3'
require 'yaml'
require 'fileutils'

DIR = ARGV.shift
DICTIONARY = YAML.load_file(File.expand_path('../dictionary.yaml', __FILE__))
EXTRAS = YAML.load_file(File.expand_path('../extras.yaml', __FILE__))
BLACKLIST = YAML.load_file(File.expand_path('../blacklist.yaml', __FILE__))
SPELLING_MISTAKES = YAML.load_file(File.expand_path('../spelling_mistakes.yaml', __FILE__)).invert

DICTIONARY.merge!(EXTRAS)
BLACKLIST.each { |b| DICTIONARY.delete(b) }

$translated = {}

class String
  def translate!(pattern, separators: '', transform: nil)
    gsub!(/(?<=^|[_\W#{separators}])#{pattern}/) do |word|
      down = word.downcase
      if DICTIONARY.key?(down)
        $translated[down] = DICTIONARY[down]
        transform ? DICTIONARY[down].send(transform) : DICTIONARY[down].downcase
      else
        word
      end
    end
    self
  end
end

def text_files(dir)
  files = Dir.glob("#{dir}/**/*").select { |file| File.file?(file) }
  types, _ = Open3.capture2('xargs', '-0', 'file', '-b', '--mime-type',
                            stdin_data: files.join("\0"))
  types = types.split("\n")
  indexes = []
  types.each_with_index { |t, i| indexes.push(i) if t =~ /^text\// }
  files.values_at(*indexes)
end

text_files(DIR).each do |file|
  source = File.read(file)
  begin
    source.translate!(/[A-Z][a-z]+/, separators: '\w', transform: :capitalize)
    source.translate!(/[A-Z]{2,}/, separators: 'a-z', transform: :upcase)
    source.translate!(/[a-z]{2,}/)
    SPELLING_MISTAKES.each { |k, v| source.gsub!(k, v) }
    File.write(file, source)
    puts "Converted: #{file}"
  rescue => ex
    warn "Couldn't convert: #{file}, #{ex}"
  end

  renamed = file.clone
              .translate!(/[A-Z][a-z]+/, separators: '\w', transform: :capitalize)
              .translate!(/[a-z]{2,}/)

  if file != renamed
    puts "Renaming: #{file} -> #{renamed}"
    FileUtils.mkdir_p(File.dirname(renamed))
    system('git', 'mv', file, renamed)
  end
end

$translated.keys.sort.each { |k| puts "#{k}: #{$translated[k]}" }
