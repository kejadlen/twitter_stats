require 'active_record'
require 'mechanize'
#require 'hpricot'
#require 'open-uri'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :dbfile => File.join(File.dirname(__FILE__), 'tweets.db')
)

class Tweet < ActiveRecord::Base
  def time
    DateTime.parse(time_before_type_cast)
  end
end

class Twitter
  def initialize(user, pass=nil)
    @user_url = "http://twitter.com/#{user}"
    @agent = WWW::Mechanize.new

    unless pass.nil?
      twitter = @agent.get('http://twitter.com/')
      signin = twitter.forms[0]
      signin.username_or_email = user
      signin.password = pass
      @agent.submit(signin, signin.buttons[0])
    end

    @doc = @agent.get(@user_url)
    @page = 1

    @tweets = [current_tweet]
    @tweets += page_to_tweets
  end

  def current_tweet
    tweet,time = @doc/'div.desc'/'p'
    tweet = tweet.inner_html
    time = DateTime.parse(time.at('abbr')['title'])

    {:tweet => tweet, :time => time}
  end

  def page_to_tweets
    (@doc/'div.tab'/'tr.hentry').map do |tweet|
      tweet,time = tweet/'span'
      tweet = tweet.inner_html.gsub(/^\s*(.*)\s*$/, '\1')
      time = DateTime.parse(time.at('abbr')['title'])

      {:tweet => tweet, :time => time}
    end
  end

  def older?
    (@doc/'div.tab'/'div.pagination'/'a').last.inner_text =~ /Older/
  end

  def succ
    if @tweets.empty?
      return nil unless older?

      @page += 1
      @doc = @agent.get("#{@user_url}?page=#{@page}")
      @tweets = page_to_tweets
    end

    @tweets.shift
  end
end
