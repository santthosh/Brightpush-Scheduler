require 'spec_helper'
require File.dirname(__FILE__) + '/../lib/sqs.rb'

describe "SQS" do
  it "should provide functionality to create a queue in SQS" do
    SQS.method_defined?(:create_queue)
  end
end