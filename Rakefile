require 'resque/tasks'
require 'sinatra'
import 'simpledb.rb'
import 'sqs.rb'
import 'schedule_apns_notifications.rb'
import 'schedule_c2dm_notifications.rb'

namespace :resque do
  task :setup do
    require 'resque'
    
    rails_env = ENV['RAILS_ENV'] || 'development'

    if rails_env == 'production'
      $redis = Redis.new(:host => 'redis.brightpush.in')
    elsif rails_env == 'staging'
      $redis = Redis.new(:host => 'redis.brightpushbeta.in')
    elsuf rails_env == 'test'
      $redis = Redis.new(:host => 'redis.brightpushalpha.in')
    else 
      $redis = 'localhost:6379'
    end
    
    # Setup the shared redis server
    Resque.redis = $redis
  end
end