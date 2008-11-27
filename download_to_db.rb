#!/usr/bin/env ruby

require 'twitter'

last_tweet = Tweet.find(:first, :order => 'time DESC')

tweets = Twitter.new(ARGV[0])

if last_tweet.nil? or tweets.current_tweet[:time] > last_tweet.time
  while tweet = tweets.succ
    break if last_tweet and tweet[:time] <= last_tweet.time

    Tweet.create(tweet)
  end
end
