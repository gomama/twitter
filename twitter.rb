#!/usr/bin/env ruby

# twitter.rb
# twitterのAPI処理を行うライブラリ
# last updated : 2010/05/27-01:01:00

require 'rubygems'
require 'oauth'
require 'json'

$TWITTER_URI = "http://twitter.com"
$TWITTER_API_URI = "http://api.twitter.com"

def return_truth_value(tv)
  return true if tv == "true"
  return false
end

class TwitterUser
  attr_accessor :id
  attr_accessor :screen_name
  attr_accessor :location
  attr_accessor :description
  attr_accessor :profile_image_url
  attr_accessor :url
  attr_writer :protected
  attr_accessor :followers_count
  attr_accessor :profile_background_color
  attr_accessor :profile_text_color
  attr_accessor :profile_link_color
  attr_accessor :profile_sidebar_fill_color
  attr_accessor :profile_sidebar_border_color
  attr_accessor :friends_count
  attr_accessor :created_at
  attr_accessor :favourites_count
  attr_accessor :utc_offset
  attr_accessor :time_zone
  attr_accessor :profile_background_image_url
  attr_writer :profile_background_tile
  attr_accessor :statuses_count
  attr_writer :notifications
  attr_writer :geo_enabled
  attr_writer :verified
  attr_writer :following

  def protected?
    return return_truth_value(protected)
  end

  def geo_enabled?
    return return_truth_value(geo_enabled)
  end

  def verified?
    return return_truth_value(verified)
  end

  def following?
    return return_truth_value(followering)
  end

  def profile_background_tile?
    return return_truth_value(profile_background_tile)
  end

end

class TwitterStatus
  attr_accessor :created_at
  attr_accessor :id
  attr_accessor :text
  attr_accessor :source
  attr_writer :truncated
  attr_accessor :in_reply_to_status_id
  attr_accessor :in_reply_to_user_id
  attr_writer :favorited
  attr_accessor :in_reply_to_screen_name
  attr_accessor :user
  attr_accessor :retweeted_status

  def truncated?
    return return_truth_value(truncated)
  end

  def favorited?
    return return_truth_value(favorited)
  end
end

class Twitter
  def initialize(user, consumer_key, consumer_secret, access_token, access_token_secret, count=20)
    consumer =
      OAuth::Consumer.new(
                          consumer_key,
                          consumer_secret,
                          :site => $TWITTER_URI
                          )
    @access_token =
      OAuth::AccessToken.new(
                             consumer,
                             access_token,
                             access_token_secret
                             )
    @user = user
    @count = count
  end

  def make_status(response)
    statuses = Array.new
    JSON.parse(response.body).each do |status|
      ts = TwitterStatus.new

      ts.created_at = status['created_at']
      ts.id = status['id']
      ts.text = status['text']
      ts.truncated = status['truncated']
      ts.source = status['source']
      ts.in_reply_to_status_id = status['in_reply_to_status_id']
      ts.in_reply_to_user_id = status['in_reply_to_user_id']
      ts.favorited = status['favorited']
      ts.in_reply_to_screen_name = status['in_reply_to_screen_name']
      if status['retweeted_status'] != nil
        rs = TwitterStatus.new
        rs.created_at = status['retweeted_status']['created_at']
        rs.id = status['retweeted_status']['id']
        rs.text = status['retweeted_status']['text']
        rs.truncated = status['retweeted_status']['truncated']
        rs.source = status['retweeted_status']['source']
        rs.in_reply_to_status_id = status['retweeted_status']['in_reply_to_status_id']
        rs.in_reply_to_user_id = status['retweeted_status']['in_reply_to_user_id']
        rs.favorited = status['retweeted_status']['favorited']
        rs.in_reply_to_screen_name = status['retweeted_status']['in_reply_to_screen_name']
        rs.user = TwitterUser.new
        rs.user.id = status['retweeted_status']['user']['id']
        rs.user.name = status['retweeted_status']['user']['name']
        rs.user.screen_name = status['retweeted_status']['user']['screen_name']
        rs.user.location = status['retweeted_status']['user']['location']
        rs.user.description = status['retweeted_status']['user']['description']
        rs.user.profile_image_url = status['retweeted_status']['user']['profile_image_url']
        rs.user.profile_text_color = status['retweeted_status']['user']['profile_text_color']
        rs.user.profile_link_color = status['retweeted_status']['user']['profile_link_color']
        rs.user.profile_sidebar_fill_color = status['retweeted_status']['user']['profile_sidebar_fill_color']
        rs.user.profile_sidebar_border_color = status['retweeted_status']['user']['profile_sidebar_border_color']
        rs.user.url = status['retweeted_status']['user']['url']
        rs.user.protected = status['retweeted_status']['user']['protected']
        rs.user.followers_count = status['retweeted_status']['user']['followers_count']
        rs.user.friends_count = status['retweeted_status']['user']['friends_count']
        rs.user.created_at = status['retweeted_status']['user']['created_at']
        rs.user.favourites_count = status['retweeted_status']['user']['favourites_count']
        rs.user.ufc_offset = status['retweeted_status']['user']['ufc_offset']
        rs.user.time_zone = status['retweeted_status']['user']['time_zone']
        rs.user.statuses_count = status['retweeted_status']['user']['statuses_count']
        rs.user.notifications = status['retweeted_status']['user']['notifications']
        rs.user.geo_enabled = status['retweeted_status']['user']['geo_enabled']
        rs.user.verified = status['retweeted_status']['user']['verified']
        rs.user.following = status['retweeted_status']['user']['following']
        ts.retweeted_status = rs
      end
      ts.user = TwitterUser.new
      ts.user.id = status['user']['id']
      ts.user.name = status['user']['name']
      ts.user.screen_name = status['user']['screen_name']
      ts.user.location = status['user']['location']
      ts.user.description = status['user']['description']
      ts.user.profile_image_url = status['user']['profile_image_url']
      ts.user.profile_text_color = status['user']['profile_text_color']
      ts.user.profile_link_color = status['user']['profile_link_color']
      ts.user.profile_sidebar_fill_color = status['user']['profile_sidebar_fill_color']
      ts.user.profile_sidebar_border_color = status['user']['profile_sidebar_border_color']
      ts.user.friends_count = status['user']['friends_count']
      ts.user.created_at = status['user']['created_at']
      ts.user.favourites_count = status['user']['favourites_count']
      ts.user.ufc_offset = status['user']['ufc_offset']
      ts.user.time_zone = status['user']['time_zone']
      ts.user.statuses_count = status['user']['statuses_count']
      ts.user.notifications = status['user']['notifications']
      ts.user.geo_enabled = status['user']['geo_enabled']
      ts.user.verified = status['user']['verified']
      ts.user.following = status['user']['following']

      statuses << ts
    end
    return statuses
  end

  def get_status(location, page, count)
    response =
      @access_token.get("#{TWITTER_API_URI}/1/statuses/#{localtion}.json?count=#{count}&page=#{page}")
    return make_status(response)
  end

  def get_friends_timeline(page, count=@count)
    return get_status("home_timeline", page, count)
  end

  def get_user_timeline(page, user=@user, count=@count)
    return get_status("user_timeline/#{user}", page, count)
  end

  def get_mentions(page, count=@count)
    return get_status("mentions", page, count)
  end

  def get_favorites(page, user=@user)
    response =
      @access_token.get("#{TWITTER_API_URI}/1/favorites/#{user}json?page=#{page}")
    return make_status(response)
  end

  def get_retweeted_by_me(page, count=@count)
    return get_status("retweeted_by_me", page, count)
  end

  def get_retweeted_to_me(page, count=@count)
    return get_status("retweeted_to_me", page, count)
  end

  def get_retweeted_of_me
    return get_status("retweeted_of_me", page, count)
  end

  def get_followers(cursor=-1)
  end

  def get_followers_id(cursor=-1)
  end

  def get_following(cursor=-1)
  end

  def get_following_id(cursor=-1)
  end

  def show_status(status_id)
  end

  def update_status(text, in_reply_to_status_id=-1)
    if text.split(//u).size >140
      raise "Tweetは140文字以下にしてください"
    end
    response =
      @access_token.post(
                         "#{TWITTER_API_URI}/1/statuses/update.json",
                         "status" => text,
                         "in_reply_to_status_id" => in_reply_to_status_id
                         )
    return response.code
  end

  def destroy_status(status_id)
    response =
      @access_token.post("#{TWITTER_API_URI}/1/statuses/destroy/#{status_id}.json")
    return response.code
  end

  def post_direct_message(text, user)
  end

  def destroy_direct_message(status_id)
  end

  def create_favorite(status_id)
    response =
      @access_token.post("#{TWITTER_API_URI}/1/favorites/create/#{status_id}.json")
    return response.code
  end

  def destroy_favorite(status_id)
    response =
      @access_token.post("#{TWITTER_API_URI}/1/favorites/destroy/#{status_id}.json")
    retrun response.code
  end

  def retweet(status_id)
    response =
      @access_token.post("#{TWITTER_API_URI}/1/statuses/retweet/#{status_id}.json")
    return reponse.code
  end

  def follow(user_id)
    response =
      @access_token.post("#{TWITTER_API_URI}/1/friendships/create/#{user_id}.json")
    return response.code
  end

  def unfollow(user_id)
    response =
      @access_token.post("#{TWITTER_API_URI}/1/friendships/destroy/#{user_id}.json")
    return response.code
  end

  def block(user_id)
  end

  def unblock(user_id)
  end

  def search_(text)
  end

  # Twitterが正常に稼働してるならtrue
  def working?
    response = @access_token.get("#{TWITTER_API_URI}/1/help/test.json")
    return true if response.code == 200
    return false
  end

end
