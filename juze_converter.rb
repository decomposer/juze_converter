#!/usr/bin/env ruby

require 'open3'
require 'yaml'
require 'fileutils'

DIR = ARGV.shift
DICTIONARY = YAML.load_file(File.expand_path('../dictionary.yaml', __FILE__))
EXTRAS = YAML.load_file(File.expand_path('../extras.yaml', __FILE__))
BLACKLIST = YAML.load_file(File.expand_path('../blacklist.yaml', __FILE__))

DICTIONARY.merge!(EXTRAS)
BLACKLIST.each { |b| DICTIONARY.delete(b) }

$translated = {}

class String
  def translate!(pattern, additional_separators = '', method = nil)
    gsub!(/(?<=^|[_\W#{additional_separators}])#{pattern}/) do |word|
      down = word.downcase
      if DICTIONARY.key?(down)
        $translated[down] = DICTIONARY[down]
        method ? DICTIONARY[down].send(method) : DICTIONARY[down].downcase
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
    source.translate!(/[A-Z][a-z]+/, '\w', :capitalize)
    source.translate!(/[A-Z]{2,}/, 'a-z', :upcase)
    source.translate!(/[a-z]{2,}/)
    File.write(file, source)
    puts "Converted: #{file}"
  rescue => ex
    warn "Couldn't convert: #{file}, #{ex}"
  end

  renamed = file.clone.translate!(/[A-Z][a-z]+/, '\w', :capitalize).translate!(/[a-z]{2,}/)

  if file != renamed
    puts "Renaming: #{file} -> #{renamed}"
    FileUtils.mkdir_p(File.dirname(renamed))
    system('git', 'mv', file, renamed)
  end
end

$translated.keys.sort.each { |k| puts "#{k}: #{$translated[k]}" }
