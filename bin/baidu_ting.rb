#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"

require "optparse"
require "fileutils"
require "eventmachine"
$:.unshift(File.join(File.dirname(__FILE__), "../lib"))
require "baidu_ting"

def usage
  puts "Usage: ruby bin/baidu_ting.rb <album_url> [-d DIRECTORY]"; exit 
end

options = {}
opts_parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby bin/baidu_ting.rb <album_url> [-d DIRECTORY]"

  opts.on('-d DIRECTORY') { |dir| options[:dir] = dir }
  opts.on('-h', '--help', 'Display this screen' ) do
    puts opts
    exit
   end
end
album_url, = opts_parser.parse!
usage unless album_url
puts album_url
BASE_FOLDER = options[:dir] || "#{Dir.home}/Music/downloads/"
CONCURRENCY = 5

def create_album_folder(name)
  name.gsub!(/^\.+/, "")
  begin
    dir = File.join(BASE_FOLDER, name) 
    FileUtils.mkdir_p(dir)
    Dir.chdir(dir)
  rescue 
    raise "Can't handle directory #{dir}"
  end
end

def download_album(album_url)
  puts "begin"

  ting = BaiduTing.new
  result = ting.song_list(album_url)
  create_album_folder(result[:title])
  size = result[:songs].size

  EM.run do
    EM.threadpool_size = CONCURRENCY
    result[:songs].each do |name, url|
      EM.defer(
        proc do 
          data = ting.download_song(name, url)
          open(name + ".mp3", "wb") do |file|
            file.write(data)
          end
        end,
        proc do
          size -= 1
          if 0 >= size
            EM.stop
            progress(ting)
            puts "Download finished!"
          end
        end)
    end

    EM.add_periodic_timer(1) {progress(ting)}
  end
end

def progress(ting)
  printf "\033M"*ting.download_status.size + "\r" if @move_up
  @move_up = true
  ting.download_status.each {|k, v| printf "%-50s\t%3d%%\n", k, v}
end

download_album(album_url)
