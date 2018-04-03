#!/usr/bin/env ruby

require 'open3'
require 'yaml'
require 'fileutils'

DIR = ARGV.shift || raise('You must specify a source directory')
DICTIONARY = YAML.load_file(File.expand_path('../dictionary.yaml', __FILE__))
               .invert.reject { |us, uk| us.size <= 2 || us == uk.gsub('-', '') }
EXTRAS = YAML.load_file(File.expand_path('../extras.yaml', __FILE__)).invert
BLACKLIST = YAML.load_file(File.expand_path('../blacklist.yaml', __FILE__))
SPELLING_MISTAKES = YAML.load_file(File.expand_path('../spelling_mistakes.yaml', __FILE__)).invert

DICTIONARY.merge!(EXTRAS)
BLACKLIST.each { |b| DICTIONARY.delete(b) }

$translated = {}

def in_ranges?(ranges, index)
  ranges.reduce(false) { |result, range| result || range.include?(index) }
end

class String
  def translate!(pattern, separators: '', transform: nil, ignore: [])
    gsub!(/(?<=^|[_\W#{separators}])#{pattern}/) do |word|
      down = word.downcase
      if DICTIONARY.key?(down) && !in_ranges?(ignore, Regexp.last_match.begin(0))
        $translated[down] = DICTIONARY[down]
        transform ? DICTIONARY[down].send(transform) : DICTIONARY[down].downcase
      else
        word
      end
    end
    self
  end
  def ranges(pattern)
    to_enum(:scan, pattern).map do
      m = Regexp.last_match
      m.begin(0)..m.begin(0) + m.to_s.size
    end
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
    ignore = source.ranges(/base64.+?["\n]/) +
             source.ranges(/\w{3,}:\/\/[\w\-:@\/\.]+/) +
             source.ranges(/\-W[a-z\-]+/) +
             source.ranges(/(NS|CG|kCT|kIOHID)[a-zA-Z]+/)
    source.translate!(/[A-Z][a-z]{2,}+/, separators: '\w', transform: :capitalize, ignore: ignore)
    source.translate!(/[A-Z]{3,}/, separators: 'a-z', transform: :upcase, ignore: ignore)
    source.translate!(/[a-z]{3,}/, ignore: ignore)
    SPELLING_MISTAKES.each { |k, v| source.gsub!(k, v) }
    File.write(file, source)
    puts "Converted: #{file}"
  rescue => ex
    warn "Couldn't convert: #{file}, #{ex}"
  end

  renamed = file.clone
              .translate!(/[A-Z][a-z]{2,}/, separators: '\w', transform: :capitalize)
              .translate!(/[a-z]{3,}/)

  if file != renamed
    puts "Renaming: #{file} -> #{renamed}"
    FileUtils.mkdir_p(File.dirname(renamed))
    system('git', 'mv', file, renamed)
  end
end

puts "\nWords translated:\n\n"

$translated.keys.sort.each { |k| puts "#{k}: #{$translated[k]}" }
