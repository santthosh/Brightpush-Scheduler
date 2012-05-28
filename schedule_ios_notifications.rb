import 'simpledb.rb'
import 'sqs.rb'

# Schedule a whole bunch of push notifications
module Schedule_iOS_PushNotifications
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
  
  # Execute the job
  def self.perform
    domain = SimpleDB.get_domain(SimpleDB.domain_for_ios_notification)
  
    unless domain.nil?
      notification_item = Schedule_iOS_PushNotifications.get_pending_notification(domain)
      
      schedule_identifier = SecureRandom.uuid
      puts "scheduler_id = #{schedule_identifier}"
      
      # if there is a notification to schedule, start, else exit
      unless notification_item.nil?
        
        # Set the scheduler_id in com.apple.notification
        Schedule_iOS_PushNotifications.set_notification_status(notification_item,"scheduling",schedule_identifier)
        
        # This is necessary so that Amazon SimpleDB updates their db
        sleep(10)
        
        # Read the scheduler_id, if it is the same set status to scheduling 
        #  -- if not quit (this means some other worker has started working)
        if schedule_identifier.to_s != notification_item.attributes['scheduler_id'].values.first.to_s
          puts "scheduler_id(#{schedule_identifier}) mismatch with 
                notification_item.scheduler_id(#{notification_item.attributes['scheduler_id'].values.first})"
          return
        end
        
        device_domain =  SimpleDB.get_domain(notification_item.attributes['bundle_id'].values.first)
        active_token_items = device_domain.items.where(:active => true)

        page = active_token_items.page(:per_page => 2500)
        queue_domain = SimpleDB.get_domain(SimpleDB.domain_for_ios_notification_queues)
        
        # This is the case when there is an array of active items
        if page.is_a?(Array) && !queue_domain.nil?
          last_page = false
          until last_page
            queue_identifier = SecureRandom.uuid
            puts "queue_id = #{queue_identifier}"
            
            # For each page, create separate SQS queue 
            queue = SQS.create_queue(queue_identifier)

            # add a record in com.apple.notification.queues, set the status to pending
            queue_item = { :scheduler_id => schedule_identifier,:created => Time.now.iso8601, :updated => Time.now.iso8601, :status => "pending" }
       	    queue_domain.items.create queue_identifier,queue_item
       	  
       	    # package these into 50 token chunks
       	    count = 0
       	    device_tokens = ""
            page.each do |item|
              if count == 0
                device_tokens << "["
              end
              
              device_tokens << "#{item.name},"
              count = count + 1
              
              if count == 50
                device_tokens << "]"
                
                # Add the notification_item.name and item.name to SQS Queue
                msg = queue.send_message("{'id':'#{notification_item.name}','devices':'#{device_tokens}'}")
                print '.'
                
                device_tokens = ""
                count = 0
              end 
            end
            
            if count > 0
              device_tokens << "]"
              
              # Add the notification_item.name and item.name to SQS Queue
              msg = queue.send_message("{'id':'#{notification_item.name}','devices':'#{device_tokens}'}")
              print '.'
              
              device_tokens = ""
              count = 0
            end
            
            puts " "
            
            if page.last_page?
              last_page = true
            else
              page = page.next_page
            end
          end
        end
        
        # After all the records have been scheduled, set the status in com.apple.notification.queues
        Schedule_iOS_PushNotifications.set_notification_status(notification_item,"scheduled")
      end
    end
  end
end