import 'lib/simpledb.rb'
import 'lib/sqs.rb'
require 'resque-status'

# Schedule a whole bunch of push notifications
class Schedule_APNS_PushNotifications
    include Resque::Plugins::Status
  @queue = :scheduler
  
  # Set the status of the notification in SimpleDB
  def self.set_notification_status(item,status,identifier = nil)
    item.attributes.replace(:status => status)
    if identifier
      item.attributes.replace(:scheduler_id => identifier)
    end
    item.attributes.replace(:updated => Time.now.iso8601)
  end
  
  # Get the notification record to process
  def self.get_pending_notification(domain,identifier = nil)
    # Look for new notifications that are yet to be scheduled in Amazon Simple DB
    results = domain.items.where("status = 'pending' AND application_type = ?","ios")
    
    return results.first;
  end
  
  def name
    return "Schedule Apple Push Notifications"
  end
  
  # Execute the job
  def perform
    domain = SimpleDB.get_domain(SimpleDB.domain_for_notification)
    
    tick()
  
    unless domain.nil?
      notification_item = Schedule_APNS_PushNotifications.get_pending_notification(domain)
      
      schedule_identifier = SecureRandom.uuid
      
      # if there is a notification to schedule, start, else exit
      unless notification_item.nil?
        
        Resque.logger.info("Starting iOS Push with scheduler_id = #{schedule_identifier} for #{notification_item.attributes['message']}")
        
        # Set the scheduler_id in com.apple.notification
        Schedule_APNS_PushNotifications.set_notification_status(notification_item,"scheduling",schedule_identifier)
        
        # This is necessary so that Amazon SimpleDB updates their db
        sleep(10)
        
        # Read the scheduler_id, if it is the same set status to scheduling 
        #  -- if not quit (this means some other worker has started working)
        if schedule_identifier.to_s != notification_item.attributes['scheduler_id'].values.first.to_s
          Resque.logger.info("scheduler_id(#{schedule_identifier}) mismatch with 
                notification_item.scheduler_id(#{notification_item.attributes['scheduler_id'].values.first})")
          return
        end
        
        bundle_identifier = notification_item.attributes['bundle_id'].values.first;
        environment = notification_item.attributes['environment'].values.first;
        
        if(environment.casecmp("sandbox") == 0)
          bundle_identifier << ".debug"
        end
        
        tick()
        
        device_domain =  SimpleDB.get_domain(bundle_identifier)
        active_token_items = device_domain.items.where(:active => true)

        total = active_token_items.count
        scheduled_count = 0
        
        page = active_token_items.page(:per_page => 2500)
        queue_domain = SimpleDB.get_domain(SimpleDB.domain_for_notification_queues)
        
        # This is the case when there is an array of active items
        if page.is_a?(Array) && !queue_domain.nil?
          last_page = false
          until last_page
            tick()
                
            queue_identifier = SecureRandom.uuid
            Resque.logger.info("queue_id = #{queue_identifier}")
            
            # For each page, create separate SQS queue 
            queue = SQS.create_queue(queue_identifier)

            # add a record in com.apple.notification.queues, set the status to pending
            queue_item = { :scheduler_id => schedule_identifier, :notification_id => notification_item.name ,:created => Time.now.iso8601, :updated => Time.now.iso8601, :status => "pending", :application_type => notification_item.attributes['application_type'].values.first }
       	    queue_domain.items.create queue_identifier,queue_item
       	  
       	    # package these into 200 token chunks
       	    count = 0
       	    device_tokens = ""
            page.each do |item|
              device_tokens << "#{item.name},"
              count = count + 1
              scheduled_count = scheduled_count + 1
              
              if count == 200
                # Add the notification_item.name and item.name to SQS Queue
                msg = queue.send_message("#{device_tokens}")
                print '.'
                # Update resque-status
                at(scheduled_count,total,"scheduling completed for #{queue_identifier}")
                
                device_tokens = ""
                count = 0
              end 
            end
            
            if count > 0
              # Add the notification_item.name and item.name to SQS Queue
              msg = queue.send_message("#{device_tokens}")
              # Update resque-status
              at(scheduled_count,total,"scheduling completed for #{queue_identifier}")
              
              device_tokens = ""
              count = 0
            end
            
            if page.last_page?
              last_page = true
            else
              page = page.next_page
            end
          end
        end
        
        # After all the records have been scheduled, set the status in com.apple.notification.queues
        Schedule_APNS_PushNotifications.set_notification_status(notification_item,"scheduled")
        
        Resque.logger.info("Scheduling completed for iOS Push with scheduler_id = #{schedule_identifier}")
      else 
        at(1,1,"No pending APNS notifications to be scheduled")
      end
    end
  end
end