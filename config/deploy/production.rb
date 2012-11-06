set :branch, "master"

role :web, "ec2-54-245-39-219.us-west-2.compute.amazonaws.com"                          # Your HTTP server, Apache/etc
role :app, "ec2-54-245-39-219.us-west-2.compute.amazonaws.com"                          # This may be the same as your `Web` server

set :rack_env,"production"

ssh_options[:user] = "ubuntu"
ssh_options[:keys] = ["/data/ops/alpha/aws-keys/us-west-oregon/brightpush-workers.pem"]