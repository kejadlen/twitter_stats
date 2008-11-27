require 'camping'
require 'gchart'
require 'mechanize'
require 'twitter'

Camping.goes :TwitterStats

def TwitterStats.create
  TwitterStats::Models.create_schema :assume => (TwitterStats::Models::User.table_exists? ? 1.0 : 0.0)
end

module TwitterStats::Models
  Base.allow_concurrency = true

  class User < Base; end

  class CreateTheBasics < V 1.0
    def self.up
      create_table :twitterstats_users, :force => true do |t|
        t.column :username, :string, :null => false
        t.column :month,    :string
        t.column :day,      :string
        t.column :hour,     :string
        t.column :replies,  :string
      end
    end

    def self.down
      drop_table :twitterstats_users
    end
  end
end

module TwitterStats::Controllers
  class Index < R '/(.+)', '/'
    def gchart_hash x, y
      {
        :width => 400,
        :height => 300,
        :extras => { 'chxt' => 'x,y', 'chxl' => "0:|#{x.join('|')}|1:#{y.join('|')}" }
      }
    end

    def get username=nil
      if username.nil?
        render :index
      else
        @user = User.find_by_username(username)

        render (@user.nil?) ? :wait : :stats
      end
    end

    def post
      utc_offset = input.utc_offset.to_i
      tweets = Twitter.new(input.username, input.password)

      month   = Array.new(12, 0)
      day     = Array.new(7, 0)
      hour    = Array.new(24, 0)
      replies = Hash.new(0)

      while t = tweets.succ
        time = t[:time]

        if time.year == 2007
          month[time.month-1] += 1
          day[time.wday] += 1
          hour[(time.hour+utc_offset)%24] += 1
          replies[$1] += 1 if t[:tweet] =~ /@<a href="\/([^"]+)">\1<\/a>/
        end
      end

      user = User.new(:username => input.username)

      user.month = GChart.bar(gchart_hash(Date::ABBR_MONTHNAMES.compact, [month.min, month.max]).merge({
        :title => 'Tweets per Month',
        :data => month,
        :orientation => :vertical
      })).to_url

      user.day = GChart.bar(gchart_hash(Date::ABBR_DAYNAMES, [day.min, day.max]).merge({
        :title => 'Tweets per Day',
        :data => day,
        :orientation => :vertical
      })).to_url

      user.hour = GChart.line(gchart_hash((0..23).to_a, [hour.min, hour.max]).merge({
        :title => 'Tweets per Hour',
        :data => hour
      })).to_url

      user.replies = replies.sort_by {|_,v| v }.reverse.map {|k,v| "#{k},#{v}" }.join("\n")

      user.save

      redirect R(Index, input.username)
    end
  end
end

module TwitterStats::Views
  def layout
    text '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
    html do
      head do
        title 'Twitter Stats'
      end
      body do
        self << yield
      end
    end
  end

  def index
    p 'Your password (if entered) and tweets are not saved.'
    form :method => 'post' do
      label 'Username', :for => 'username'; br
      input :name => 'username', :type => 'text'; br

      label 'Password (only required to access protected tweets)', :for => 'password'; br
      input :name => 'password', :type => 'password'; br

      label 'UTC offset (EST: -5, PST: -8)', :for => 'utc_offset'; br
      input :name => 'utc_offset', :type => 'text'; br
    end
  end

  def wait
    p 'Your stats are being generated. Try again in a couple minutes!'
  end

  def stats
    p { img :src => @user.month }
    p { img :src => @user.day }
    p { img :src => @user.hour }
    p 'Top Replies:'
    p do
      table do
        @user.replies.split("\n").map {|pair| pair.split(',') }.each do |k,v|
          tr do
            td k
            td v
          end
        end
      end
    end
  end
end
