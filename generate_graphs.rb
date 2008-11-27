#!/usr/bin/env ruby

require 'gchart'
require 'twitter'

month_data = Array.new(12, 0)
day_data = Array.new(7, 0)
hour_data = Array.new(24, 0)
reply_data = Hash.new(0)

Tweet.find(:all).select {|t| t.time.year == 2007 }.each do |t|
  month_data[t.time.month-1] += 1
  day_data[t.time.wday] += 1
  hour_data[(t.time.hour-8)%24] += 1
  reply_data[$1] += 1 if t[:tweet] =~ /@<a href="\/([^"]+)">\1<\/a>/
end

def min_max_label(data)
  "|#{data.min}|#{data.max}"
end

puts GChart.bar(
  :title => 'Tweets per Hour',
  :data => hour_data,
  :width => 400,
  :height => 300,
  :extras => { 'chxt' => 'x,y', 'chxl' => "0:|#{(0..23).to_a.join('|')}|1:#{min_max_label(hour_data)}" },
  :orientation => :vertical
).to_url

puts GChart.bar(
  :title => 'Tweets per Day',
  :data => day_data,
  :width => 400,
  :height => 300,
  :extras => { 'chxt' => 'x,y', 'chxl' => "0:|#{Date::ABBR_DAYNAMES.compact.join('|')}|1:#{min_max_label(day_data)}" },
  :orientation => :vertical
).to_url

puts GChart.bar(
  :title => 'Tweets per Month',
  :data => month_data,
  :width => 400,
  :height => 300,
  :extras => { 'chxt' => 'x,y', 'chxl' => "0:|#{Date::ABBR_MONTHNAMES.compact.join('|')}|1:#{min_max_label(month_data)}" },
  :orientation => :vertical
).to_url

reply_data = reply_data.sort_by {|_,v| v }.reverse
reply_data.each {|k,v| puts "#{k}: #{v}" }
reply_labels = reply_data.map {|k,_| k }
reply_data = reply_data.map {|_,v| v }
puts GChart.bar(
  :title => 'Most Replies',
  :data => reply_data,
  :width => 400,
  :height => 300,
  :extras => { 'chxt' => 'x,y', 'chxl' => "0:|#{reply_labels.join('|')}|1:#{min_max_label(reply_data)}" },
  :orientation => :vertical
).to_url
