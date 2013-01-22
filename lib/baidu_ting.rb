require 'open-uri'
require 'mechanize'

class BaiduTing
  BASE_URL   = "http://music.baidu.com"
  LOGIN_URL  = "https://passport.baidu.com/v2/api/?login"
  TITLE_PATH = '//h2[@class="album-name"]'
  SONGS_PATH = '//span[@class="song-title "]/a'
  FINAL_PATH = '//li[@class="high-rate"]'
  attr_accessor :download_status

  def initialize(name, password)
    @agent = Mechanize.new
    @agent.user_agent_alias = 'Mac Safari'
    @agent.agent.http.ca_file = '/etc/ssl/certs/ca-certificates.crt' if File.exists?('/etc/ssl/certs/ca-certificates.crt') # for Ubuntu
    @name = name
    @password = password
  end

  def login
    #get cookie
    @agent.get(BASE_URL)

    resp = @agent.get("https://passport.baidu.com/v2/api/?getapi&class=login&tpl=mn&tangram=true")
    #parse body to get token
    matcher = resp.body.to_s.match(/login_token\=\'(.+)\'/)
    token = matcher[1]

    res = @agent.post(LOGIN_URL, {
      "username" => @name,
      "password" => @password,
      "token"    => token,
      "ppui_logintime" => 9379,
      "charset" => "utf-8",
      "codestring" => "",
      "isPhone" => false,
      "index" => 0,
      "u" => "",
      "safeflg" => 0,
      "staticpage" => "http%3A%2F%2Fwww.baidu.com%2Fcache%2Fuser%2Fhtml%2Fjump.html",
      "loginType" => 1,
      "tpl" => "mn",
      "callback" => "parent.bdPass.api.login._postCallback",
      "verifycode" => "",
      "mem_pass" => "on"
      })
    matcher = res.body.to_s.match (/error=(\d+)&/)
    status = matcher[1]
    status == "0"
  end

  def song_url(href)
    # should exclude non-mp3 songs
    return nil unless href.include? "song"

    url = "#{BASE_URL}#{href}/download"
    @agent.get(url) do |page|
      #default low definition music
      path = page.link_with(:id => "download").attributes["href"]

      #find high definition music
      node = page.parser.xpath(FINAL_PATH).first
      if node
        data = node["data-data"]
        matcher = data.match(/"link":"(.*)"/)
        path = matcher[1].gsub("\\/", "/")
      end
      return BASE_URL + path
    end
  end

  def song_list(url)
    unless login
      puts "Login failed"
      exit
    end

    title = songs = nil
    @agent.get(URI.parse(url)) do |page|
      page_content = page.parser

      #get title and song path
      title = page_content.xpath(TITLE_PATH)[0].text.strip
      songs = page_content.xpath(SONGS_PATH).select { |n| !n.text.strip.empty? }
    end

    @download_status = {}
    songs.each {|song| @download_status[song.text.strip] = 0}
    song_titles = songs.collect {|song| song.text.strip}
    song_urls = songs.collect {|song| song_url(song["href"])}

    {:title => title,
     :songs => Hash[song_titles.zip(song_urls)]}
  end

  def download_song(name, url)
    get_page(url, name)
  end

  def get_page(url, update_key = nil)
    if update_key
      total_len = 0
      url = URI.parse(URI.encode(url))
      open(url,
           :content_length_proc => lambda do |len|
             if len && 0 < len
               total_len = len
             end
           end,
           :progress_proc => lambda { |s| @download_status[update_key] = s * 100 / total_len }
          ) { |f| f.read }
    else
      open(url)
    end
  end
end
