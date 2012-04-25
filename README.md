baidu-ting
Download all the songs in an album from http://ting.baidu.com. Code in ruby.

Prerequisite:
1. install nokogiri
gem install nokogiri
2. change the base folder
change "BASE_FOLDER" to the folder where you want to download the album, e.g. "C:" or "/tmp/".

How to use:
ruby baidu_ting.rb album_url 
"album_url" should be replaced by the album address, e.g. "http://ting.baidu.com/album/13947931" without quotes