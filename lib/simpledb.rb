require 'aws'
require 'yaml'
import 'lib/logger.rb'

# Helper class to manage simple_db
class SimpleDB
  
  def self.domain_for_ios_notification
    config = YAML.load_file("config/aws.yml")
    return config[ENV['RACK_ENV']]["notifications_domain"]
  end
  
  def self.domain_for_ios_notification_queues
    config = YAML.load_file("config/aws.yml")
    return config[ENV['RACK_ENV']]["notifications_queues_domain"]
  end
  
  # Connect to Simple DB
  def self.get_domain(identifier)
    config = YAML.load_file("config/aws.yml")
        
    client = AWS::SimpleDB.new(
              :access_key_id => config[ENV['RACK_ENV']]["access_key_id"],
              :secret_access_key => config[ENV['RACK_ENV']]["secret_access_key"])
    domain = client.domains[identifier]
    
    begin
    	if domain.exists?
    		Logger.instance.log("Selecting domain '#{identifier}'")
    	  return domain
    	else 
    	  Logger.instance.log("Selected domain '#{identifier}' doesn't exist")
    	  return nil
    	end
    rescue AWS::SimpleDB::Errors::InvalidParameterValue => e
    	puts e.message
      return nil
    end

    return nil
  end
end