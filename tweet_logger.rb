#!/usr/bin/env ruby

# tweet_logger.rb
# last updated : 2010/05/23-14:09:23
# OAuth認証を利用してTwitterのログを毎日取得＆はてダに保存

require 'rubygems'
require 'oauth'
require 'json'
require 'open-uri'
require 'date'
require 'mechanize'
require 'nkf'
require 'kconv'

# OAuth認証の情報
$CONSUMER_KEY = 'IgyDtvsHRpjNBV7Xns0W4g'
$CONSUMER_SECRET = 'B3VGgRG4k2BwSPahQA3Dv7dMd5iY0hZjbb0sXdPmc'
$ACCESS_TOKEN = '15047650-jHPahSqTXHTFzuZ9KbE7IwQPjp8DIymRQJu8l6etS'
$ACCESS_TOKEN_SECRET ='P2CSUISuSgtsotenyiNJ2Xn1JB0ljPBjNWx7qCDufnQ'

# twitter
$TWITTER_URI = 'http://api.twitter.com'
$USERNAME = 'gomama'
$COUNT = '200'


# hatena
$HATENA_URI = 'http://twitter.g.hatena.ne.jp/'
$HATENA_ID = "goman"
$HATENA_PASS = "RyM8ElUN"

class TwitterOAuth
  def initialize
    # OAuth初期設定
    @consumer =
      OAuth::Consumer.new(
                          $CONSUMER_KEY,
                          $CONSUMER_SECRET,
                          :site => 'http://twitter.com'
                          )

    @access_token =
      OAuth::AccessToken.new(
                             @consumer,
                             $ACCESS_TOKEN,
                             $ACCESS_TOKEN_SECRET
                             )

  end

  # Twitterからデータの取得
  def get_tweet_per_day(get_day = Date.today)
    # Tweet保存用ハッシュ
    tweet = Hash.new()

    page = 1
    err_count = 0
    eflag = true

    puts "Twitterからログの取得中..."
    begin
      while eflag
        puts "page=#{page}" if $DEBUG
        response = @access_token.get('#{$TWITTER_URI}/1/statuses/user_timeline.json?count=#{$COUNT}&page=#{page}')
        JSON.parse(response.body).each do |status|
          time = DateTime.parse(status['created_at']).new_offset(Rational(3,8))
          temp_date = Date.new(time.year, time.month, time.day)
          if temp_date < get_day
            eflag = false
            break
          elsif temp_date == get_day
            tweet_id = status['id'].to_s
            post = status['text'].chomp
            permalink = "http://twitter.com/#{$USERNAME}/statuses/" + tweet_id
            tweet[permalink] = [tweet_id,post,time]
            # p tweet[permalink] if $DEBUG
            puts post if $DEBUG
          end
        end
        page += 1
      end
    rescue => ex
      puts "Error: #{ex}"
      puts "Response Code: #{response.code}"
      sleep 10
      err_count += 1
      retry if err_count < 100
      return tweet, false
    end
    puts "Twitterからの取得終了"
    return tweet, true
  end

  def post_tweet(text)
    err_count = 0

    puts "Twitterへ書き込み中..."
    begin
      response =
        @access_token.post(
                           'http://twitter.com/statuses/update.json',
                           'status' => text
                           )
      puts "Response Code: #{response.code}"
    rescue => ex
      puts "Error: #{ex}"
      puts "Response Code: #{response.code}"
      err_count += 1
      sleep 10
      retry if err_count < 100
      return
    end
  end

  ## get followers or friends list
  def get_follow_list(arg)
    err_count = 0
    uri = "#{$TWITTER_URI}/1/#{arg}/ids.json?cursor="
    cursor = "-1"
    list = Array.new

    begin
      loop {
        #
        response = @access_token.get(uri+cursor)
        status = JSON.parse(response.body)

        # 次ページのポインタを取得しておく
        cursor = status['next_cursor_str']
        # id を配列に格納 (一度で5000id)
        status['ids'].each do |id|
          list << id
          puts id if $DEBUG
        end
        puts "next cursor=#{cursor}" if $DEBUG

        # next_cursor == 0 で終了
        break if cursor == '0'
      }
    rescue => ex
      err_count += 1
      puts ex.message
      sleep 10
      retry if err_count < 100
      return nil
    end
    return list
  end

  ## followers or friends diff
  def get_diff_follow(arg)
    # 前回取得したリスト読み込み
    previous_list = Array.new
    open(arg+'.txt','r').each do |id|
      previous_list << id.chomp!.to_i
    end

    # 現在のリストをTwitterから取得
    current_list = get_follow_list(arg)

    if current_list == nil
      puts "Error: Twitterからリストが取得できませんでした"
      return nil,nil
    end
    # 差分を計算
    removed = previous_list - current_list
    added = current_list - previous_list

    # 現在のリストを出力しておく
    open(arg+'.txt','w').puts(current_list)

    # 差分を返す
    return removed, added
  end

  def check_follow
    puts "follwers diff"
    puts "removed, added"
    p get_diff_follow('followers')
    puts "friends diff"
    puts "removed, added"
    p get_diff_follow('friends')
  end

end





# はてなダイアリーへ書き込む
def post_to_hatena(date, title, text)
  err_count = 0
  puts "はてなダイアリーへ書き込み処理開始..."
  begin
    agent = WWW::Mechanize.new

    # 日記のページを取得してログインボタンをおす
    diary_page = agent.get($HATENA_URI)
    login_page = diary_page.link_with(:text => "ログイン").click

    puts "ログイン処理中..."

    # ログインする
    login_form = login_page.forms.first
    login_form['name'] = $HATENA_ID
    login_form['password'] = $HATENA_PASS
    agent.submit(login_form)

    puts "ログインしました"
    puts "書き込み中..."

    # 日記を書く
    diary_page = agent.get($HATENA_URI)
    edit_page = diary_page.link_with(:text => "日記を書く").click
    edit_form = edit_page.forms_with(:name => 'edit').first
    date += 1
    edit_form['year'] = date.year.to_s
    edit_form['month'] = date.month.to_s
    edit_form['day'] = date.day.to_s
    edit_form['title'] = title.toutf8
    edit_form['body'] = text.toutf8
    ok_button = edit_form.button_with(:name => 'edit')
    agent.submit(edit_form, ok_button)

    puts "はてなダイアリーに書き込みました"

  rescue => ex
    err_count += 1
    puts "Error: #{$@}:#{ex.message}"
    puts "はてなダイアリーへの書き込みが失敗しました(#{err_count}回目)"
    sleep 5
    retry if err_count < 50
    return false
  end

  return true
end



#
# ここからメイン処理
#

# 引数がなければ昨日の日付、あればその日を指定
if ARGV.empty?
  date = Date.today-1
else
  date = Date.new(ARGV[0].to_i,ARGV[1].to_i,ARGV[2].to_i) end

# はてダ用タイトルと本文
post_title = ""
post_text = ""

# Twitterからログ取得
twitter = TwitterOAuth.new

=begin

tweet, code = twitter.get_tweet_per_day(date)
if code
  tweet.sort{|a,b| a[1][0] <=> b[1][0]}.each do |key, value|
    post_text += sprintf "-<a href=\"%s\">%02d:%02d:%02d</a> %s\n", key, value[2].hour, value[2].min, value[2].sec, value[1]
  end

  puts post_text if $DEBUG

  post_to_hatena(date, post_title, post_text) if !$DEBUG

  tweet_text = sprintf "%04d年%02d月%02d日は%d回つぶやいたよ [auto]", date.year, date.month, date.day, tweet.length
  twitter.post_tweet(tweet_text) if !$DEBUG
else
  twitter.post_tweet('なんかよくわかんないけどログ取得ミスった！ [auto]') if !$DEBUG
end

=end

# followers 及び friends を取得し、差分を表示
twitter.check_follow
