require 'open-uri'
require 'nokogiri'

BASE_URL = 'http://ting.baidu.com'
BASE_FOLDER = '.'

def create_album_folder(name)
  begin
    Dir.chdir(BASE_FOLDER)
    Dir.mkdir(name)
    Dir.chdir(BASE_FOLDER + '/' + name)
  rescue 
    raise "Can't handle directory #{title}"
  end
end

def download_album(album_url)
  puts "begin"

  page_content = Nokogiri::HTML(open(album_url))
  title = page_content.xpath('//dd[@class="album-title"]')[0].text
  create_album_folder(title)

  threads = []

  page_content.xpath('//span[@class="song-title"]/a').each do |node|
    threads << Thread.new do
      song_url = BASE_URL + node['href'] + '/download'
      song_name = node.text
      begin
        puts "Downloading: #{song_name}"
        get_song(song_url, song_name)
      rescue Exception => e
        raise "Can't get song: #{song_name}"
      end
      puts "Finished: #{song_name}"
    end
  end

  threads.each {|thread| thread.join}
  puts "Download over!"
end

def get_song(url, name)
  page_content = Nokogiri::HTML(open(url))
  path = page_content.xpath('//a[@class="btn-download"]')[0]['href']
  puts "#{name} real address is #{BASE_URL + path}"
  
  open(name + ".mp3", "wb") do |file|
    file.write(open(BASE_URL + path).read)
  end
end

download_album(ARGV[0])