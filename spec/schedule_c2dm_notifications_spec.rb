require 'spec_helper'
require File.dirname(__FILE__) + '/../lib/schedule_c2dm_notifications.rb'

describe "Schedule_C2DM_PushNotifications" do
  it "should schedule c2dm notifications for Android devices" do
    Schedule_C2DM_PushNotifications.method_defined?(:perform)
  end
end