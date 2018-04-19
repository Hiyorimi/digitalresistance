# gem install aws-sdk-ec2
require 'aws-sdk-ec2'

AWS_KEY = '...'
AWS_SECRET = '...'

REGIONS = ['...', '...']

def print_and_flush(str)
  print str
  $stdout.flush
end

def valid_ip?(ip)
  `python3 is-banned.py #{ip}`.strip == '0'
end

REGIONS.each do |region|

  puts "Region: #{region}"

  ec2 = Aws::EC2::Client.new({
                                 region: region,
                                 credentials: Aws::Credentials.new(AWS_KEY, AWS_SECRET)
                             })

  describe_addresses_result = ec2.describe_addresses({})

  puts "  #{describe_addresses_result.addresses.count} IPs"

  describe_addresses_result.addresses.each do |address|

    first_time = true
    valid = nil
    instance_id = address.instance_id

    invalid_count = 0

    _address = address

    while invalid_count < 5 && (valid == false || first_time)

      unless first_time

        puts "    release address..."
        ec2.release_address({allocation_id: _address.allocation_id})

        puts "    allocate new address..."
        _address = ec2.allocate_address({})

      end

      print_and_flush "   #{_address.public_ip} check ..."
      valid = valid_ip?(_address.public_ip)
      puts " - #{ valid ? 'valid' : 'banned!' }"

      invalid_count += 1 unless valid

      if valid && first_time == false

        puts "    associate instance #{instance_id}..."

        ec2.associate_address({
                                  allocation_id: _address.allocation_id,
                                  instance_id: instance_id,
                              })

        puts "    reboot instance..."

        ec2.reboot_instances({instance_ids: [instance_id]})

      end

      first_time = false

    end

  end
end