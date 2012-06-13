require 'aws'
require 'yaml'

# Helper class to manage simple_db
class SimpleDB
  
  def self.domain_for_ios_notification
    return "com.apple.notifications"
    # return "in.brightpush.notifications"
  end
  
  def self.domain_for_ios_notification_queues
    return "com.apple.notifications.queues"
    # return "in.brightpush.notifications.queues"
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
    		puts "Selecting domain '#{identifier}'"
    	  return domain
    	else 
    	  puts "Selected domain '#{identifier}' doesn't exist"
    	  return nil
    	end
    rescue AWS::SimpleDB::Errors::InvalidParameterValue => e
    	puts e.message
      return nil
    end

    return nil
  end
end