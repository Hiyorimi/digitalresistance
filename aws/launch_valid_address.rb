# gem install aws-sdk-ec2
require 'aws-sdk-ec2'

AWS_KEY = '...'
AWS_SECRET = '...'

region = '...'

def print_and_flush(str)
  print str
  $stdout.flush
end

def valid_ip?(ip)
  `python3 is-banned.py #{ip}`.strip == '0'
end


ec2 = Aws::EC2::Client.new({
                               region: region,
                               credentials: Aws::Credentials.new(AWS_KEY, AWS_SECRET)
                           })

first_time = true
valid = nil
address = nil

while valid == false || first_time

  if address
    puts "release address..."
    ec2.release_address({allocation_id: address.allocation_id})
  end

  puts "allocate new address..."
  address = ec2.allocate_address({})

  print_and_flush "#{address.public_ip} check ..."
  valid = valid_ip?(address.public_ip)
  puts " - #{ valid ? 'valid' : 'banned!' }"

  first_time = false

end