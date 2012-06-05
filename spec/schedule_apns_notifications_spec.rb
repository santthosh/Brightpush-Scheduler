require 'spec_helper'
require File.dirname(__FILE__) + '/../lib/schedule_apns_notifications.rb'

describe "Schedule_APNS_PushNotifications" do
  it "should schedule push notifications for iOS devices" do
    Schedule_APNS_PushNotifications.method_defined?(:perform)
  end
end