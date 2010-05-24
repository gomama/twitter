#!/usr/bin/env ruby

# post_with_oauth.rb
# last updated : 2010/05/23-16:09:04
# OAuth認証を利用してtwitterにAccess!

require 'rubygems'
require 'oauth'
require 'json'
require 'date'

CLIENT_NAME = "まじごまま"

CONSUMER_KEY = 'IgyDtvsHRpjNBV7Xns0W4g'
CONSUMER_SECRET = 'B3VGgRG4k2BwSPahQA3Dv7dMd5iY0hZjbb0sXdPmc'
ACCESS_TOKEN = '15047650-jHPahSqTXHTFzuZ9KbE7IwQPjp8DIymRQJu8l6etS'
ACCESS_TOKEN_SECRET ='P2CSUISuSgtsotenyiNJ2Xn1JB0ljPBjNWx7qCDufnQ'

$KCODE = "utf8"

# 初期設定

$count = 20
$showtime = false
$showclient = false
$showstatusid = false
$autoupdate = 30

while !$*.empty?
  arg = $*.shift
  if arg =~ /^c([0-9]+)/
    $count = $1
  elsif arg =~ /^showtime$/
    $showtime = true
  elsif arg =~ /^showclient$/
    $showclient = true
  elsif arg =~ /^showstatusid$/
    $showstatusid = true
  end
end

consumer =
  OAuth::Consumer.new(
                      CONSUMER_KEY,
                      CONSUMER_SECRET,
                      :site => 'http://twitter.com'
                      )

$access_token =
  OAuth::AccessToken.new(
                         consumer,
                         ACCESS_TOKEN,
                         ACCESS_TOKEN_SECRET
                         )

$statusid = Array.new


# タイムライン取得

def get_timeline(pos)
  response = $access_token.get("http://twitter.com/#{pos}.json?count=#{$count}")
  JSON.parse(response.body).reverse_each do |status|
    print "#{status['user']['screen_name']}"
    if $showtime
      time = DateTime.parse(status['created_at']).new_offset(Rational(3,8))
      printf " at %02d:%02d:%02d", time.hour, time.min, time.sec
    end
    if $showclient
      /^(?:<a href=\"[^>]*>)?([^<]*)(?:<\/a>)?$/ =~ status['source']
      print " from #{$1}"
    end
    print(":\n\s\s")
    print status['text'].scan(/.{40}|.+$/).join("\n\s\s")
    if $showstatusid
      $statusid << [status['id'],status['user']['screen_name']]
      print " (#{$statusid.size-1})"
    end
    print("\n")
  end
end


# メイン
puts "Welcome to #{CLIENT_NAME}"
loop do
  begin
    print ">"
    command = gets.chomp

    # command分岐
    case command

    # 指定idへreply
    when /^re\s/i
      spcmd  = command.split(/\s/)
      id = $statusid[spcmd[1].to_i][0]
      user = $statusid[spcmd[1].to_i][1]
      tweet = spcmd[2]
      response =
        $access_token.post(
                           'http://twitter.com/statuses/update.json',
                           'status' => "@#{user} #{tweet}",
                           'in_reply_to_status_id' => id
                           )

    # timelineの表示
    when /^(tl|)$/i
      get_timeline("statuses/friends_timeline")

    # mentionsの表示
    when /^me$/i
      get_timeline("statuses/mentions")

    # favoritesの表示
    when /^fav$/i
      get_timeline("favorites")

    # 自分の発言一覧の表示
    when /^my$/i
      get_timeline("statuses/user_timeline")

    # 指定したユーザのタイムラインの表示
    when /^u\s/
      user = command.split(/\s/)[1]
      get_timeline("statuses/user_timeline/#{user}")

    # Option設定
    when /^o$/
      # countの設定
      print "count (def:20): "
      $count = gets.chomp!.to_i
      $count = 20 if $count == 0
      if $count >200
        $count = 200
      elsif $count < 1
        $count = 1
      end

      # タイムライン表示時に時間も表示するかどうか
      begin
        print "Show updated time? (y or n def:n): "
        flg = gets.chomp
        if flg =~ /^y(es)*$/i
          $showtime = true
        elsif flg =~ /^(no*|)$/i
          $showtime = false
        else
          raise "Error: Please input y or n"
        end
      rescue => ex
        puts ex.message
        retry
      end

      # タイムライン表示時にクライアント名も表示するかどうか
      begin
        print "Show Client name? (y or n def:n): "
        flg = gets.chomp
        if flg =~ /^y(es)*$/i
          $showclient = true
        elsif flg =~ /^(no*|)$/i
          $showclient = false
        else
          raise "Error: Please input y or n"
        end
      rescue => ex
        puts ex.message
        retry
      end

      # タイムライン表示時にステータスidも表示するかどうか
      begin
        print "Show Status id? (y or n def:n)"
        flg = gets.chomp
        if flg =~ /^y(es)*$/i
          $showstatusid = true
        elsif flg =~ /^(no*|)$/i
          $showstatusid = false
        else
          raise "Error: Please input y or n"
        end
      rescue => ex
        puts ex.message
        retry
      end

    # スクリプト終了
    when /^s$/i
      break

    # ヘルプ
    when /^h$/
      puts "re (id) hoge: reply to id"
      puts "tl: Get friend_timeline"
      puts "me: Get mentions"
      puts "fav: Get favorites"
      puts "my: Get my timeline"
      puts "u user: Get user timeline"
      puts "o: option"
      puts "h: help"
      puts "s: stop this script"

    # それ以外はTwitterにPost
    else
      response =
        $access_token.post(
                           'http://twitter.com/statuses/update.json',
                           'status' => command
                           )
    end
  rescue => ex
    puts "Error: #{ex.message}"
  end
end
