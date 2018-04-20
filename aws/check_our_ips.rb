# gem install aws-sdk-ec2
# gem install net-ssh
require 'aws-sdk-ec2'
require 'json'
require 'net/http'
require 'net/ssh'

AWS_KEY = ENV['AWS_KEY']
AWS_SECRET = ENV['AWS_SECRET']


REGIONS = ['eu-central-1', 'us-east-1', 'us-east-2', 'us-west-2', 'ap-northeast-1', 'eu-west-3', 'ca-central-1', 'ap-northeast-2', 'ap-south-1', 'eu-west-1', 'ap-southeast-1']

def print_and_flush(str)
  print str
  $stdout.flush
end

def valid_ip?(ip)
  JSON.parse(Net::HTTP.get(URI("https://tgproxy.me/rkn/backend.php?ip=#{ip}")))['blocked'] == false
end

REGIONS.each do |region|

  ec2_client = Aws::EC2::Client.new({
                                        region: region,
                                        credentials: Aws::Credentials.new(AWS_KEY, AWS_SECRET)
                                    })

  ec2_resource = Aws::EC2::Resource.new({
                                            region: region,
                                            credentials: Aws::Credentials.new(AWS_KEY, AWS_SECRET)
                                        })

  describe_addresses_result = ec2_client.describe_addresses({})

  puts "Region #{region}, #{describe_addresses_result.addresses.count} IPs"

  describe_addresses_result.addresses.each do |address|

    puts "  #{address.public_ip}:"

    instance_id = address.instance_id
    instance = ec2_resource.instance(instance_id)

    puts "    instance state: #{instance.state.name}"

    need_reboot_instance = false

    begin
      ssh = Net::SSH.start(instance.public_dns_name, 'admin')
      tm_info = ssh.exec!('curl -4 -s "https://statistic-instance.appspot.com/info?tag=$(curl -4 -s https://statistic-instance.appspot.com/tag)"')
      ssh.close
    rescue
      need_reboot_instance = true
      puts "    connect failed"
    end

    unless need_reboot_instance

      if tm_info.to_s.strip.length == 0
        need_reboot_instance = true
        puts "    Telegram info is not available"
      end

      unless need_reboot_instance

        telegram_status = /External issues: ([\s\w\d]+)\./.match(tm_info) && /External issues: ([\s\w\d]+)\./.match(tm_info)[1]

        puts "    Telegram status: #{telegram_status}"
        puts "    users: #{/Has (\d+) connected clients/.match(tm_info) && /Has (\d+) connected clients/.match(tm_info)[1]}"


        need_reboot_instance = true if telegram_status.nil? || telegram_status.downcase.include?('disabled') || telegram_status.downcase.include?('banned')
      end

    end

    first_time = true
    valid = nil
    invalid_count = 0

    if need_reboot_instance
      valid = false
      first_time = false
    end

    _address = address

    while invalid_count < 10 && (valid == false || first_time)

      unless first_time

        puts "    release address..."
        ec2_client.release_address({allocation_id: _address.allocation_id})

        puts "    allocate new address..."
        _address = ec2_client.allocate_address({})

      end

      print_and_flush "    check ip..."
      valid = valid_ip?(_address.public_ip)
      puts " - #{ valid ? 'valid' : 'banned!' }"

      invalid_count += 1 unless valid

      if valid && first_time == false

        puts "    associate instance #{instance_id}..."

        ec2_client.associate_address({
                                         allocation_id: _address.allocation_id,
                                         instance_id: instance_id,
                                     })

        puts "    reboot instance..."
        ec2_client.reboot_instances({instance_ids: [instance_id]})

      end

      first_time = false

    end

    puts " "

  end
end
