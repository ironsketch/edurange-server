# This file contains the implementation of the AWS API calls. They are implemented
# as hooks, called dynamically by the {Provider} concern when {Scenario}, {Cloud}, {Subnet}, and {Instance} are booted.
# @see Provider#boot
require 'active_support'
module Aws
  extend ActiveSupport::Concern

  ##############################################################
  # Booting

  # Cloud

  def aws_cloud_boot(options)
    
    raise 'AWS: driver id already set' if self.driver_id != nil

    vpc = aws_cloud_vpc_create(options)

    internet_gateway = aws_cloud_internet_gateway_create(vpc, options)

    aws_cloud_wait_till_available(vpc, options)
    
    aws_cloud_routing_rules_create(vpc, options)

    aws_cloud_tags_create(vpc, options)
  rescue => e
    debug options, "AWS: error: #{e.message.to_s} #{e.backtrace}"
    if vpc
      debug options, "AWS: cleaning up Cloud '#{vpc.id}'"
      aws_cloud_internet_gateway_delete(vpc, options)
      aws_cloud_acls_delete(vpc, options)
      aws_cloud_security_groups_delete(vpc, options)
      aws_cloud_route_tables_delete(vpc, options)
      aws_cloud_vpc_delete(vpc, options)
    end
    self.update_attribute(:driver_id, nil)
    raise 'AWS: finished cleaning up'
  end

  def aws_cloud_vpc_create(options)
    self.debug options, "AWS: creating VPC"
    vpc = AWS::EC2.new.vpcs.create(self.cidr_block)
    self.update_attribute(:driver_id, vpc.id)
    self.debug options, "AWS: created VPC '#{vpc.id}'"
    vpc
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  end

  def aws_cloud_internet_gateway_create(vpc, options)
    self.debug options, "AWS: creating InternetGateway"
    internet_gateway = vpc.internet_gateway = AWS::EC2.new.internet_gateways.create
    self.debug options, "AWS: created InternetGateway '#{internet_gateway.id}'"
    internet_gateway
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  end

  def aws_cloud_wait_till_available(vpc, options)
    self.debug options, "AWS: waiting for VPC '#{vpc.id}' to become available"
    Timeout.timeout(30) { sleep 1 while vpc.state != :available}
  rescue Timeout::Error => e
    raise "AWS: timeout waiting for VPC '#{vpc.id}' to become available"
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  end

  def aws_cloud_routing_rules_create(vpc, options)
    
    debug options, "AWS: getting VPC '#{vpc.id}' SecurityGroup"
    begin
      security_group = vpc.security_groups.first
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    debug options, "AWS: creating rules for SecurityGroup '#{security_group.id}'"
    begin
      security_group.authorize_ingress(:tcp, 20..8080) #enable all traffic inbound from port 20 - 8080 (most we care about)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      security_group.revoke_egress('0.0.0.0/0') # Disable all outbound
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    
    begin
      security_group.authorize_egress('0.0.0.0/0', protocol: :tcp, ports: 80)  # Enable port 80 outbound
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      security_group.authorize_egress('0.0.0.0/0', protocol: :tcp, ports: 443) # Enable port 443 outbound
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      security_group.authorize_egress('10.0.0.0/16') # enable all traffic outbound to subnets
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
  end

  def aws_cloud_tags_create(vpc, options)
    name = "#{Rails.configuration.x.aws['iam_user_name']}-#{self.scenario.user.name}-#{self.scenario.name}-#{self.scenario.id.to_s}"
    host = Rails.configuration.x.aws['iam_user_name']
    instructor = self.scenario.user.name
    scenario_id = self.scenario.id

    self.debug options, "AWS: creating Tags for VPC '#{vpc.id}'"
    begin
      vpc.tag("Name", value: name)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.tag("host", value: host)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.tag("instructor", value: instructor)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.tag("scenario", value: scenario_id)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    self.debug options, "AWS: creating Tags for InternetGateway '#{vpc.id}'"
    begin
      vpc.internet_gateway.tag("Name", value: name)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.internet_gateway.tag("host", value: host)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.internet_gateway.tag("instructor", value: instructor)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.internet_gateway.tag("scenario", value: scenario_id)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    self.debug options, "AWS: creating Tags for SecurityGroup '#{vpc.security_groups.first.id}'"
    begin
      vpc.security_groups.first.tag("Name", value: name)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.security_groups.first.tag("host", value: host)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.security_groups.first.tag("instructor", value: instructor)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.security_groups.first.tag("scenario", value: scenario_id)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    self.debug options, "AWS: creating Tags for NetworkACL '#{vpc.network_acls.first.id}'"
    begin
      vpc.network_acls.first.tag("Name", value: name)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.network_acls.first.tag("host", value: host)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.network_acls.first.tag("instructor", value: instructor)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.network_acls.first.tag("scenario", value: scenario_id)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    self.debug options, "AWS: creating Tags for RouteTable '#{vpc.route_tables.first.id}'"
    begin
      vpc.route_tables.first.tag("Name", value: name)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.route_tables.first.tag("host", value: host)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.route_tables.first.tag("instructor", value: instructor)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
    begin
      vpc.route_tables.first.tag("scenario", value: scenario_id)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
  end

  def aws_cloud_unboot(options)
    vpc = aws_cloud_vpc_get(options)
    aws_cloud_internet_gateway_delete(vpc, options)
    aws_cloud_acls_delete(vpc, options)
    aws_cloud_security_groups_delete(vpc, options)
    aws_cloud_route_tables_delete(vpc, options)
    aws_cloud_vpc_delete(vpc, options)
    self.update_attribute(:driver_id, nil)
  rescue => e
    raise "AWS: failed to unboot Cloud '#{self.driver_id}': #{e.message} #{e.backtrace}"
  end

  def aws_cloud_vpc_get(options)
    debug options, "AWS: getting VPC '#{self.driver_id}'"
    return AWS::EC2.new.vpcs[self.driver_id]
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  end

  def aws_cloud_internet_gateway_delete(vpc, options)
    begin

      begin
        internet_gateway = vpc.internet_gateway
      rescue AWS::EC2::Errors::RequestLimitExceeded => e
        sleep 1
        retry
      end

      begin
        exists = internet_gateway.exists?
      rescue AWS::EC2::Errors::RequestLimitExceeded => e
        sleep 1
        retry
      end

      if exists
        begin
          debug options, "AWS: detaching InternetGateway '#{internet_gateway.internet_gateway_id}'"
          internet_gateway.detach(vpc)
        rescue AWS::EC2::Errors::RequestLimitExceeded => e
          sleep 1
          retry
        end

        begin
          debug options, "AWS: deleting InternetGateway '#{internet_gateway.internet_gateway_id}'"
          internet_gateway.delete
        rescue AWS::EC2::Errors::RequestLimitExceeded => e
          sleep 1
          retry
        end
      end

    rescue => e
      debug options, "AWS: error deleting VPC '#{vpc.id}' internet gateway: #{e.message.to_s}"
    end
  end

  def aws_cloud_acls_delete(vpc, options)

    begin
      vpc.network_acls.select{ |acl| !acl.default}.each do |acl|
        begin
          debug options, "AWS: deleting ACL '#{acl.network_acl_id}'"
          acl.delete
        rescue => e
          debug options, "AWS: error deleting ACL '#{acl.network_acl_id}'"
        end
      end
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
  end

  def aws_cloud_security_groups_delete(vpc, options)
    begin
      vpc.security_groups.select{ |sg| !sg.name == "default"}.each do |security_group|
        begin
          debug options, "AWS: deleting SecurityGroup '#{security_group.security_group_id}'"
          security_group.delete
        rescue => e
          debug options, "AWS: error deleting SecurityGroup '#{security_group.security_group_id}'"
        end
      end
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
  end

  def aws_cloud_route_tables_delete(vpc, options)
    begin
      vpc.route_tables.select{ |rt| !rt.main?}.each do |route_table|
        begin
          debug options, "AWS: deleting RouteTable '#{route_table.route_table_id}'"
          route_table.delete
        rescue => e
          debug options, "AWS: error deleting RouteTable '#{route_table.route_table_id}'"
        end
      end
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
  end

  def aws_cloud_vpc_delete(vpc, options)
    begin
      debug options, "AWS: deleting VPC '#{vpc.id}'"
      vpc.delete
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    rescue => e
      debug(options, "AWS: error deleting VPC '#{vpc.id}': #{e.message.to_s}")
    end
  end

  # Subnet

  def aws_subnet_boot(options)
    raise 'AWS: driver id already set' if self.driver_id != nil

    subnet = aws_subnet_create(options)    

    aws_subnet_wait_till_available(subnet, options)

    route_table = aws_subnet_create_route_table(subnet, options)
    
    vpc = aws_subnet_vpc_get(options)

    aws_subnet_vpc_internet_gateway_route_create(vpc, route_table, options) if self.internet_accessible

    aws_subnet_route_table_tags_create(subnet, route_table, options)

    aws_subnet_create_route_to_nat(route_table, options) if not self.internet_accessible
  rescue => e
    debug options, "AWS: error: #{e.message.to_s} #{e.backtrace}"
    debug options, "AWS: cleaning up Subnet"
    aws_subnet_unboot(options)
    debug options, "AWS: finished cleaning up Subnet"
    raise "AWS: failed to boot Subnet"
  end

  def aws_subnet_create(options)
    debug options, "AWS: creating Subnet"
    subnet = AWS::EC2::SubnetCollection.new.create(self.cidr_block, vpc_id: self.cloud.driver_id)
    self.update_attribute(:driver_id, subnet.id)
    debug options, "AWS: created Subnet '#{subnet.id}'"
    subnet
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  end

  def aws_subnet_wait_till_available(subnet, options)
    debug options, "AWS: waiting for Subnet '#{subnet.id}' to become available"
    Timeout.timeout(30) { sleep 1 while subnet.state != :available}
  rescue Timeout::Error => e
    raise "AWS: timeout waiting for Subnet '#{subnet.id}' to become available"
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  end

  def aws_subnet_create_route_table(subnet, options)
    debug options, "AWS: creating RouteTable for '#{subnet.id}'"
    begin
      route_table = AWS::EC2::RouteTableCollection.new.create(vpc_id: self.cloud.driver_id)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    debug options, "AWS: assigned RouteTable '#{route_table.id}' to '#{subnet.id}'"
    begin
      subnet.route_table = route_table
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    route_table
  end

  def aws_subnet_vpc_get(options)
    debug options, "AWS: getting VPC '#{self.cloud.driver_id}'"
    return AWS::EC2.new.vpcs[self.cloud.driver_id]
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  end

  def aws_subnet_vpc_internet_gateway_route_create(vpc, route_table, options)
    begin
      debug options, "AWS: creating route from RouteTable '#{route_table.id}' to InternetGateway '#{vpc.internet_gateway.id}'"
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      route_table.create_route("0.0.0.0/0", { internet_gateway: vpc.internet_gateway} )
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
  end

  def aws_subnet_route_table_tags_create(subnet, route_table, options)
    name = "#{Rails.configuration.x.aws['iam_user_name']}-#{self.scenario.user.name}-#{self.scenario.name}-#{self.scenario.id.to_s}"
    host = Rails.configuration.x.aws['iam_user_name']
    instructor = self.scenario.user.name
    scenario_id = self.scenario.id

    debug options, "AWS: creating Tags for Subnet '#{subnet.id}'"
    begin
      subnet.tag("Name", value: name)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      subnet.tag("host", value: host)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      subnet.tag("instructor", value: instructor)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      subnet.tag("scenario", value: scenario_id)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    debug options, "AWS: creating Tags for RouteTable '#{route_table.id}'"
    begin
      route_table.tag("Name", value: name)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      route_table.tag("host", value: host)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      route_table.tag("instructor", value: instructor)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      route_table.tag("scenario", value: scenario_id)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
  end

  def aws_subnet_create_route_to_nat(route_table, options)
    if nat = self.scenario.nat_instance
      if nat.driver_id
        debug options, "AWS: creating Route for Subnet #{self.driver_id} to NAT Instance #{nat.driver_id}"
        begin
          route_table.create_route("0.0.0.0/0", { instance: nat.driver_id } )
        rescue AWS::EC2::Errors::RequestLimitExceeded => e
          sleep 1
          retry
        rescue => e
          debug options, "AWS: error creating route from Subnet #{self.subnet.driver_id} to NAT Instance #{nat.driver_id} #{e.message.to_s}"
        end
      end
    end
  end

  def aws_subnet_unboot(options)
    aws_subnet_route_table_disassociate(options)
    aws_subnet_delete(options)
    self.update_attribute(:driver_id, nil)
  rescue => e
    raise "AWS: failed to unboot Subnet #{self.driver_id}: #{e.message}"
  end

  def aws_subnet_route_table_disassociate(options)
    return if not self.driver_id

    begin
      debug options, "AWS: getting Subnet '#{self.driver_id}' RouteTableAssociation"
      rta = AWS::EC2.new.subnets[self.driver_id].route_table_association
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      if not rta.main?
        debug options, "AWS: RouteTableAssociation '#{rta.id}'"
        rta.delete
      end
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    rescue => e
      debug options, "AWS: error deleting RouteTableAssociation '#{rta.id}': #{e.message.to_s}"
    end
  end

  def aws_subnet_delete(options)
    return if not self.driver_id
    debug options, "AWS: deleting Subnet '#{self.driver_id}'"
    begin
      AWS::EC2.new.subnets[self.driver_id].delete
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    rescue => e
      debug options, "AWS: error deleting Subnet '#{self.driver_id}': #{e.message.to_s}"
    end
  end

  # Instance

  def aws_instance_boot(options)
    raise 'AWS: driver id already set' if self.driver_id != nil

    aws_instance_S3_files_create(options)

    instance = aws_instance_create(options)

    aws_instance_tags_create(instance, options)

    aws_instance_wait_till_available(instance, options)

    aws_instance_create_elastic_ip(instance, options) if self.internet_accessible

    aws_instance_create_route_to_nat(options) if self.os == 'nat'
  rescue => e
    debug options, "AWS: error: #{e.message.to_s} #{e.backtrace}"
    aws_instance_unboot(options)
    raise "AWS: failed to boot Instance"
  end

  def aws_instance_create(options)
    debug options, "AWS: creating Instance"
    timeout = 30
    begin
      instance = AWS::EC2::InstanceCollection.new.create(
        image_id: Rails.configuration.x.aws[Rails.configuration.x.aws['region']]["ami_#{self.os}"], 
        private_ip_address: self.ip_address,
        key_name: Rails.configuration.x.aws['ec2_key_pair_name'],
        user_data: self.generate_init,
        instance_type: "t2.micro",
        subnet: self.subnet.driver_id
      )
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    rescue AWS::EC2::Errors::InvalidSubnetID::NotFound => e
      raise "timeout waiting for Subnet #{self.subnet.driver_id}" if timeout == 0
      sleep 1
      timeout += 1
      retry
    rescue => e
      raise "AWS: error creating Instance: #{e.message}"
    end

    self.update_attribute(:driver_id, instance.id)
    debug options, "AWS: created Instance '#{instance.id}'"
    instance
  end

  def aws_instance_tags_create(instance, options)
    debug options, "AWS: creating tags for Instance '#{instance.id}'"
    begin
      instance.tag("Name", value: Rails.configuration.x.aws['iam_user_name'] + "-" + self.scenario.user.name + '-' + self.scenario.name + '-' + self.scenario.id.to_s)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      instance.tag("host", value: Rails.configuration.x.aws['iam_user_name'])
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      instance.tag("instructor", value: self.scenario.user.name)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      instance.tag("scenario", value: self.scenario.id)
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end 
  end

  def aws_instance_wait_till_available(instance, options)
    debug options, "AWS: waiting for Instance '#{instance.id}' to become available"
    timeout = 60*4
    begin
      timeout2 = 60*4
      until instance.status == :running
        raise "AWS: timeout waiting for Instance '#{instance.id}' to become available" if timeout2 == 0
        timeout2 -= 1
        sleep 1
      end
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    rescue AWS::EC2::Errors::InvalidInstanceID::NotFound => e
      raise "AWS: timeout waiting for Instance '#{instance.id}' to become available" if timeout == 0
      timeout -= 1
      sleep 1
      retry
    end
  end

  def aws_instance_create_elastic_ip(instance, options)
      debug options, "AWS: creating ElasticIP"
      begin
        elastic_ip = AWS::EC2::ElasticIpCollection.new.create(vpc: true)
      rescue AWS::EC2::Errors::RequestLimitExceeded => e
        sleep 1
        retry
      end 

      debug options, "AWS: waiting for ElasticIP to become available"
      begin
        Timeout.timeout(60) { sleep 1 while not elastic_ip.exists? }
      rescue AWS::EC2::Errors::RequestLimitExceeded => e
        sleep 1
        retry
      end 

      debug options, "AWS: associating ElastipIP '#{elastic_ip.public_ip}' with Instance '#{instance.id}'"
      begin
        instance.associate_elastic_ip(elastic_ip)
      rescue AWS::EC2::Errors::RequestLimitExceeded => e
        sleep 1
        retry
      end

      debug options, "AWS: disabling source dest checks for Instance '#{instance.id}'"
      begin
        instance.network_interfaces.first.source_dest_check = false
      rescue AWS::EC2::Errors::RequestLimitExceeded => e
        sleep 1
        retry
      end 
  rescue Timeout::Error => e
    raise "AWS: timeout waiting for ElasticIP to become available"
  end

  def aws_instance_create_route_to_nat(options)
    debug options, "AWS: creating Route for Subnet '#{self.subnet.driver_id}' to NAT Instance '#{self.driver_id}'"
    self.scenario.subnets.select { |s| s.driver_id and !s.internet_accessible }.each do |subnet|
      begin
        AWS::EC2.new.subnets[subnet.driver_id].route_table.create_route("0.0.0.0/0", { instance: self.driver_id } )
      rescue AWS::EC2::Errors::RequestLimitExceeded => e
        sleep 1
        retry
      rescue => e
        deubg options, "AWS: error creating route from Subnet #{self.subnet.driver_id} to NAT Instance #{self.driver_id} #{e.message.to_s}"
      end
    end
  end

  def aws_instance_unboot(options)
    debug options, "AWS: unbooting Instance"

    return if not self.driver_id

    instance, exists = aws_instance_get(options)

    if exists
      aws_instance_volumes_delete_on_termination_set(instance, options)

      aws_instance_elastic_ip_disassociate_and_delete(instance, options)

      aws_instance_delete(instance, options)

      aws_instance_wait_till_terminated(instance, options)
    end

    aws_instance_S3_files_save(options)
    self.scenario.statistic.data_process

    aws_instance_S3_files_delete(options)
  rescue => e
    raise "AWS: failed to unboot Instance '#{self.driver_id}': #{e.message}"
  end

  def aws_instance_S3_files_save(options)
    time = Time.now.strftime("%y_%m_%d")
    bucket = aws_S3_bucket_get(options)

    path = self.scenario.statistic.data_path_instance(self.name)

    debug options, "AWS: saving bash history from Instance '#{self.name}'"
    File.open(self.scenario.statistic.data_instance_bash_histories_path(self.name), "w") do |f| 
      f.write(aws_S3_object_read(bucket, aws_S3_object_name('bash_history'), options) )
    end

    debug options, "AWS: saving exit status from Instance '#{self.name}'"
    File.open(self.scenario.statistic.data_instance_exit_statuses_path(self.name), "w") do |f| 
      f.write(aws_S3_object_read(bucket, aws_S3_object_name('exit_status'), options) )
    end

    debug options, "AWS: saving script log from Instance '#{self.name}'"
    File.open(self.scenario.statistic.data_instance_script_logs_path(self.name), "w") do |f| 
      f.write(aws_S3_object_read(bucket, aws_S3_object_name('script_log'), options) )
    end
  end

  def aws_instance_S3_files_delete(options)
    bucket = aws_S3_bucket_get(options)
    aws_instance_S3_object_delete(bucket, aws_S3_object_name('cookbook'), :cookbook_url, options)
    aws_instance_S3_object_delete(bucket, aws_S3_object_name('com'), :com_page, options)
    aws_instance_S3_object_delete(bucket, aws_S3_object_name('bash_history'), :bash_history_page, options)
    aws_instance_S3_object_delete(bucket, aws_S3_object_name('exit_status'), :exit_status_page, options)
    aws_instance_S3_object_delete(bucket, aws_S3_object_name('script_log'), :script_log_page, options)
  end

  def aws_instance_get(options)
    debug options, "AWS: getting Instance '#{self.driver_id}'"
    instance = AWS::EC2.new.instances[self.driver_id]
    exists = instance.exists?
    return instance, exists
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  end

  def aws_instance_volumes_delete_on_termination_set(instance, options)
    debug options, "AWS: setting Instance '#{self.driver_id}' volumes deleteOnTermination"
    instance.block_devices.each do |device|
      AWS::EC2.new.client.modify_instance_attribute(
        instance_id: instance.id,
        attribute: "blockDeviceMapping",
        block_device_mappings: [device_name: "#{device[:device_name]}", ebs:{ delete_on_termination: true}]
       )
    end
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  end

  def aws_instance_elastic_ip_disassociate_and_delete(instance, options)
    debug options, "AWS: looking for Instance '#{self.driver_id}' ElasticIP"
    begin
      elastic_ip = instance.elastic_ip
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    return if not elastic_ip

    debug options, "AWS: disassociating ElasticIP '#{elastic_ip.public_ip}'"
    begin
      instance.disassociate_elastic_ip
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    debug options, "AWS: deleting ElasticIP '#{elastic_ip.public_ip}'"
    begin
      elastic_ip.delete
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
  end

  def aws_instance_delete(instance, options)
    debug options, "AWS: deleting Instance '#{self.driver_id}'"
    instance.delete
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  rescue AWS::Core::Resource::NotFound => e
    return
  end

  def aws_instance_wait_till_terminated(instance, options)
    debug options, "AWS: waiting for Instance '#{self.driver_id}' to terminate"
    begin
      Timeout.timeout(60*4) { sleep 1 while not instance.status_code == 48}
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end
  rescue Timeout::Error => e
    raise "AWS: timeout waiting for Instance '#{self.driver_id}' to terminate"
  end

  # # Boots {Instance}, generating required cookbooks and startup scripts.
  # # This method largely defers to {InstanceTemplate} in order to generate shell scripts and
  # # chef scripts to configure each instance.
  # # Additionally, it uploads and stores the cookbook_url, which is generated by calling {#aws_instance_upload_cookbook}
  # # @return [nil]
  def aws_boot_instance(options = {})
    self.set_booting

    if self.driver_id == nil
      self.set_booting

      # scoring
      if self.roles.select { |r| r.recipes.find_by_name('scoring') }.size > 0
        begin
          self.aws_instance_initialize_scoring
          self.reload
          self.scenario.update_attribute(:scoring_pages_content, self.scenario.read_attribute(:scoring_pages_content) + self.scoring_page + "\n")
          self.scenario.aws_scenario_write_to_scoring_pages
        rescue => e
          self.boot_error(e)
          return false
        end
      end

      # create intitiation scripts
      debug "creating - Instance init"
      begin
        debug "generating - instance cookbook"
        self.aws_instance_create_com_page
        self.aws_instance_create_bash_history_page
        self.aws_instance_create_exit_status_page
        self.aws_instance_create_script_log_page

        debug "uploading - instance cookbook"
        self.aws_instance_upload_cookbook(self.generate_cookbook)
        
        debug "generating - instance chef script"
        cloud_init = self.generate_init
      rescue => e
        self.boot_error(e)
        return false
      end

      # get ami based on OS
      if self.os == 'nat'
        aws_instance_ami = Rails.configuration.x.aws[Rails.configuration.x.aws['region']]['ami_nat']
      elsif self.os == 'ubuntu'
        aws_instance_ami = Rails.configuration.x.aws[Rails.configuration.x.aws['region']]['ami_ubuntu']
      end

      # create EC2 Instance
      debug "creating - EC2 Instance"
      instance_type_num = 0
      tries = 0
      # instance_types = ["t1.micro", "m3.micro", "t1.small", "m3.small"]
      # instance_types = ["t1.micro"]
      instance_types = ["t2.micro"]
      begin
        debug "tyring Instance Type #{instance_types[instance_type_num]}"
        ec2instance = AWS::EC2::InstanceCollection.new.create(
          image_id: aws_instance_ami, # ami_id string of os image
          private_ip_address: self.ip_address, # ip string
          key_name: Rails.configuration.x.aws['ec2_key_pair_name'], # keypair string
          user_data: cloud_init, # startup data
          instance_type: instance_types[instance_type_num],
          subnet: self.subnet.driver_id
        )
        debug "updating instance attribute"
        self.update_attribute(:driver_id, ec2instance.id)
        debug "updated instance attribute - #{self.driver_id}"
      rescue NoMethodError => e
        debug "- NoMethodError"
        self.boot_error(e)
        return false
      rescue AWS::EC2::Errors::InvalidParameterCombination => e
        debug "- InvalidParameterCombination"
        # wrong instance type
        self.boot_error(e)
        return false
      rescue AWS::EC2::Errors::InvalidSubnetID::NotFound => e
        debug "- InvalidSubnet"
        tries += 1
        if tries > 3
          self.boot_error(e)
          return false
        end
        sleep 2
        retry
      rescue AWS::EC2::Errors::InsufficientInstanceCapacity => e
        debug "- InsufficientInstanceCapacity"
        if instance_type_num <= instance_types.size
          instance_type_num += 1
          retry
        else
          self.boot_error(e)
          return false
        end
      rescue AWS::EC2::Errors::Unsupported => e
        debug "- Unsupported"
        tries += 1
        if tries > 3
          self.boot_error(e)
          return false
        end
        sleep 10
        retry
      rescue => e
        debug "- Other Error"
        self.boot_error(e)
        return false
      end

      # wait for Instance to become available
      debug "waiting for - EC2 Instance #{self.driver_id} to become available"
      tries = 0
      begin
        cnt = 0
        until ec2instance.status == :running
          sleep 2**cnt
          cnt += 1
          if cnt == 20
            raise "Timeout Waiting for VPC to become available"
            self.boot_error($!)
            return false
          end
        end
      rescue AWS::EC2::Errors::InvalidInstanceID::NotFound => e
        if tries > 5
          self.boot_error(e)
          return false
        end
        tries += 1
        sleep 3
        retry
      rescue => e
        self.boot_error(e)
        return false
      end

      # for Internet Accessible instances
      if self.internet_accessible
        # create Elastip IP
        debug "creating - EC2 Elastic IP"
        begin
          ec2eip = AWS::EC2::ElasticIpCollection.new.create(vpc: true)
        rescue => e
          self.boot_error(e)
          return false
        end

        # wait for EIP to become available
        cnt = 0
        until ec2eip.exists?
          debug "waiting for - EC2 Elastic IP #{self.driver_id} to become available"
          sleep 2**cnt
          cnt += 1
          if cnt == 20
            raise "Timeout Waiting for VPC to become available"
            self.boot_error($!)
            return false
          end
        end

        # associate instance with EIP
        debug "associating - EC2 Elastip IP with EC2 Instance #{ec2instance.id}"
        begin
          ec2instance.associate_elastic_ip(ec2eip)
        rescue => e
          self.boot_error(e)
          return false
        end

        # accept packets coming in
        debug "accepting - EC2 Instance NIC packets, disabe source dest checks"
        begin
          ec2instance.associate_elastic_ip(ec2eip)
          ec2instance.network_interfaces.first.source_dest_check = false
        rescue => e
          self.boot_error(e)
          return false
        end
      end

      # create route table to the nat if instances subnet is not internet accessible
      if not self.subnet.internet_accessible
        debug "creating - Route for EC2 Subnet #{self.driver_id} to NAT"
        begin
          nat = self.scenario.instances.select{|i| i.internet_accessible and i.os == "nat" }.first
          if nat
            debug "waiting - for nat to boot to make route"
            until nat.booted?
              sleep 1
              nat.reload
            end
            AWS::EC2.new.subnets[self.subnet.driver_id].route_table.create_route("0.0.0.0/0", { instance: nat.driver_id } )
          end
        rescue => e
          self.boot_error(e)
          return false
        end
      end
      
      # create tags
      debug "creating tag"
      begin
        AWS::EC2.new.tags.create(ec2instance, "Name", value: Rails.configuration.x.aws['iam_user_name'] + "-" + self.scenario.user.name + '-' + self.scenario.name + '-' + self.scenario.id.to_s)
        AWS::EC2.new.tags.create(ec2instance, "host", value: Rails.configuration.x.aws['iam_user_name'])
        AWS::EC2.new.tags.create(ec2instance, "instructor", value: self.scenario.user.name)
        AWS::EC2.new.tags.create(ec2instance, "scenario", value: self.scenario.id)
      rescue => e
        self.boot_error(e)
        return false
      end
    
      self.set_booted
      self.debug_booting_finished
      debug "[x] booted - Instance #{self.name}"
    else
      debug "tried to boot but instance is not stopped. keep going."
    end
    
    true
  end

  def aws_unboot_instance(options = {})

    # check if instance exists

    debug "getting - EC2 Instance #{self.driver_id}"
    begin
      ec2instance = AWS::EC2.new.instances[self.driver_id]
    rescue => e
      self.unboot_error(e)
      return false
    end

    debug "setting - EC2 Instance #{self.driver_id} volumes deleteOnTermination"
    begin
      ec2instance.block_devices.each do |device|
        AWS::EC2.new.client.modify_instance_attribute(
          instance_id: ec2instance.id,
          attribute: "blockDeviceMapping",
          block_device_mappings: [device_name: "#{device[:device_name]}", ebs:{ delete_on_termination: true}]
         )
      end
    rescue => e
      self.unboot_error(e)
      return false
    end

    debug "deleting any - EC2 Instance EIP's"
    begin
      if ec2eip = ec2instance.elastic_ip
        ec2instance.disassociate_elastic_ip
        ec2eip.delete
      end
    rescue => e
      self.unboot_error(e)
      return false
    end

    debug "deleting - EC2 Instance #{self.driver_id}"
    begin
      ec2instance.delete
    rescue => e
      self.unboot_error(e)
      return false
    end

    debug "stopping - EC2 Instance #{self.driver_id}"

    # wait for instance to terminate
    begin
      cnt = 0
      until ec2instance.status_code == 48
        debug "waiting #{(2**cnt).to_s} seconds for - EC2 Instance #{self.driver_id} to terminate"
        sleep 2**cnt
        cnt += 1
        if cnt > 9
          raise "EC2 Instance Terminate Wait Timeout"
          self.unboot_error($!)
          return false
        end
      end
    rescue => e
      self.unboot_error(e)
      return false
    end

    # remove s3 files
    debug "removing s3 files"
    begin
      self.aws_instance_delete_cookbook
      self.aws_instance_delete_com_page
      self.aws_instance_delete_scoring_page
    rescue => e
      self.unboot_error(e)
      return false
    end

    self.update_attribute(:driver_id, nil)
    self.set_stopped
    self.debug_unbooting_finished
    true
  end

  def aws_pause_instance
    if (not self.driver_id) or (not self.booted?)
      return false
    end

    self.set_pausing
    begin
      i = AWS::EC2.new.instances[self.driver_id]
      return if not i.exists?
      i.stop

      cnt = 0
      until i.status == :stopped
        sleep 2**cnt
        cnt += 1
        if cnt == 20
          raise "Timeout Waiting for VPC to stop"
          self.boot_error($!)
          return
        end
      end
    rescue => e
      self.boot_error(e)
      return false
    end

    self.set_paused
    true
  end

  def aws_start_instance
    if (not self.driver_id) or (not self.paused?)
      return false
    end

    self.set_starting
    begin
      i = AWS::EC2.new.instances[self.driver_id]
      return if not i.exists?
      i.start

      cnt = 0
      until i.status == :running
        sleep 2**cnt
        cnt += 1
        if cnt == 20
          raise "Timeout Waiting for VPC to start"
          self.boot_error($!)
          return false
        end
      end
    rescue => e
      self.boot_error(e)
      return false
    end

    self.set_booted
    true
  end

  # Uses memoization to cache this lookup for faster page renders
  # @return [String] The public IP address belonging to {Instance}'s AWS Instance Object
  def aws_instance_public_ip
    return false unless self.driver_id
    return false unless self.internet_accessible

    cnt = 0
    begin 
      return @public_ip ||= AWS::EC2::InstanceCollection.new[self.driver_id].public_ip_address
    rescue AWS::EC2::Errors::InvalidInstanceID::NotFound => e
      if cnt < 60
        sleep 1
        cnt += 1
        retry
      else
        return false
      end
    rescue AWS::Core::Resource::NotFound => e
      return false
    end

  end
  # just put this in the model, why fetch it everytime from AWS, it never changes

  def aws_instance_S3_files_create(options)
    bucket = aws_S3_bucket_get(options)

    aws_instance_S3_object_create(bucket, aws_S3_object_name('exit_status'), :exit_status_page, :write, { expires: 30.days, :content_type => 'text/plain' }, options)
    aws_instance_S3_object_create(bucket, aws_S3_object_name('script_log'), :script_log_page, :write, { expires: 30.days, :content_type => 'text/plain' }, options)

    cookbook_object = aws_instance_S3_object_create(bucket, aws_S3_object_name('cookbook'), :cookbook_url, :read, { expires: 30.days }, options)
    bash_history_object = aws_instance_S3_object_create(bucket, aws_S3_object_name('bash_history'), :bash_history_page, :write, { expires: 30.days, :content_type => 'text/plain' }, options)
    com_page_object = aws_instance_S3_object_create(bucket, aws_S3_object_name('com'), :com_page, :write, { expires: 30.days, :content_type => 'text/plain', endpoint: Rails.configuration.x.aws[Rails.configuration.x.aws['region']]['s3_endpoint'] }, options)

    aws_S3_object_write(cookbook_object, self.generate_cookbook, options)
    aws_S3_object_write(bash_history_object, self.generate_init, options)
    aws_S3_object_write(com_page_object, 'waiting', options)
  end

  def aws_instance_S3_object_create(bucket, name, attribute, url_method, url_options, options)
    object = aws_S3_object_get(bucket, name, options)
    self.update_attribute(attribute, aws_S3_bucket_url_get(object, url_method, url_options, options))
    object
  end

  def aws_instance_S3_object_delete(bucket, name, attribute, options)
    return if self.send(attribute.to_s) == ""
    aws_S3_object_delete(aws_S3_object_get(bucket, name, options), options)
    self.update_attribute(attribute, "")
  end

  def aws_S3_object_name(suffix)
    "#{Rails.configuration.x.aws['iam_user_name']}_#{self.scenario.user.name}_#{self.scenario.name}_#{self.scenario.id.to_s}_#{self.name}_#{self.id.to_s}_#{self.uuid[0..5]}_#{suffix}"
  end

  def aws_S3_bucket_get(options)

    begin
      s3 = AWS::S3.new
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      debug options, "AWS: getting S3 Bucket '#{Rails.configuration.x.aws['s3_bucket_name']}'"
      bucket = s3.buckets[Rails.configuration.x.aws['s3_bucket_name']]
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    begin
      exists = bucket.exists?
    rescue AWS::EC2::Errors::RequestLimitExceeded => e
      sleep 1
      retry
    end

    if not exists
      begin
        debug options, "AWS: creating S3 Bucket '#{Rails.configuration.x.aws['s3_bucket_name']}'"
        s3.buckets.create(Rails.configuration.x.aws['s3_bucket_name'])
      rescue AWS::EC2::Errors::RequestLimitExceeded => e
        sleep 1
        retry
      end
    end

    bucket
  end

  def aws_S3_object_get(bucket, name, options)
    debug options, "AWS: getting S3Object '#{name}'"
    bucket.objects[name]
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  end

  def aws_S3_object_read(bucket, name, options)
    object = aws_S3_object_get(bucket, name, options)
    debug options, "AWS: reading S3Object '#{object.key}'"
    object.read
  rescue AWS::S3::Errors::NoSuchKey => e
    return ""
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  end

  def aws_S3_object_write(object, text, options)
    debug options, "AWS: writing to S3Object '#{object.key}'"
    object.write(text)
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  end

  def aws_S3_bucket_url_get(object, method, options_url, options)
    debug options, "AWS: getting S3Object url '#{object.key}'"
    object.url_for(method, options_url).to_s
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  end

  def aws_S3_object_delete(object, options)
    debug options, "AWS: dseleting S3Object '#{object.key}'"
    object.delete
  rescue AWS::EC2::Errors::RequestLimitExceeded => e
    sleep 1
    retry
  rescue => e
    debug options, "AWS: error deleting S3Object '#{object.key}'"
  end


end
