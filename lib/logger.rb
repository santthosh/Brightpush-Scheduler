require 'singleton'
require 'logglier'
require 'yaml'

# Helper class to manage Logs
class Logger
  
  include Singleton
  
  # Create an SQS queue
  def initialize
    config = YAML.load_file("config/aws.yml")
    
    @log = Logglier.new(config[ENV['RACK_ENV']]["loggly_input"])
  end
  
  def log(msg)
    @log.info(msg)
  end
end