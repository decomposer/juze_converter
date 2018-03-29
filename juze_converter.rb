#!/usr/bin/env ruby

require 'open3'
require 'yaml'
require 'fileutils'

DIR = ARGV.shift
WORDS = YAML.load_file(File.expand_path('../words.yaml', __FILE__))
BLACKLIST = YAML.load_file(File.expand_path('../blacklist.yaml', __FILE__))
BLACKLIST.each { |b| WORDS.delete(b) }
$translated = {}

class String
  def translate!(pattern, method = nil)
    gsub!(/(^|[_\W])(#{pattern})/) do
      space = Regexp.last_match[1]
      word = Regexp.last_match[2]
      down = word.downcase
      if WORDS.key?(down)
        $translated[down] = WORDS[down]
        space + (method ? WORDS[down].send(method) : WORDS[down].downcase)
      else
        space + word
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
    source.translate!(/[a-z]{2,}/)
    source.translate!(/[A-Z]{2,}/, :upcase)
    source.translate!(/[A-Z][a-z]+/, :capitalize)
    File.write(file, source)
    puts "Converted: #{file}"
  rescue => ex
    warn "Couldn't convert: #{file}, #{ex}"
  end

  renamed = file.clone.translate!(/[a-z]{2,}/).translate!(/[A-Z][a-z]+/, :capitalize)

  if file != renamed
    puts "Renaming: #{file} -> #{renamed}"
    FileUtils.mkdir_p(File.dirname(renamed))
    system('git', 'mv', file, renamed)
  end
end

$translated.keys.sort.each { |k| puts "#{k}: #{$translated[k]}" }
