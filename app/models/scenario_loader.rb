class InvalidYAMLError < StandardError; end

class ScenarioLoader
  def initialize(**args)
    @user = args[:user]
    @name = args[:name]
    @location = args[:location] || :production
  end

  def build_scenario!
    @scenario = Scenario.new(user: @user, name: @name, location: @location)
    create_scenario! if @scenario.save
  end

  private

  def create_scenario!
    begin
      load_metadata
      build_roles
      build_clouds
      build_groups
      build_questions
    rescue => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      binding.pry if Rails.env.development? || Rails.env.test?
      @scenario.destroy!
      return nil
    end

    if @scenario.valid?
      return @scenario
    else
      @scenario.destroy!
      return nil
    end
  end

  def yaml
    return nil unless @scenario
    @yaml ||= YAML.load_file(@scenario.path_yml)
  end

  def load_metadata
    @scenario.update!(
      name: yaml["Name"],
      description: yaml["Description"],
      instructions: yaml["Instructions"],
      instructions_student: yaml["InstructionsStudent"],
      uuid: generate_uuid
    )
  end

  def build_roles
    return if yaml["Roles"].nil?
    yaml_is_array!(yaml["Roles"], "Roles")
    yaml["Roles"].each { |role_hash| @scenario.roles.create!(role_attributes(role_hash)) }
  end

  def role_attributes(hash)
    raise InvalidYAMLError, "role is not a hash" unless hash.respond_to?(:map)
    {
      name: hash["Name"],
      packages: hash["Packages"],
      recipes: recipes_from_names(hash["Recipes"])
    }
  end

  def recipes_from_names(names)
    raise InvalidYAMLError, "\"Recipes\" is not an array" unless names.respond_to?(:map)
    names.map { |n| @scenario.recipes.find_or_create_by(name: n) }
  end

  def build_clouds
    return if yaml["Clouds"].nil?
    yaml_is_array!(yaml["Clouds"], "Clouds")
    yaml["Clouds"].each do |cloud_hash|
      cloud = @scenario.clouds.create!(cloud_attributes(cloud_hash))
      build_subnets(cloud, cloud_hash["Subnets"])
    end
  end

  def cloud_attributes(hash)
    raise InvalidYAMLError, "cloud is not a hash" unless hash.respond_to?(:map)
    {
      name: hash["Name"],
      cidr_block: hash["CIDR_Block"]
    }
  end

  def build_subnets(cloud, subnet_hashes)
    return if subnet_hashes.nil? || cloud.invalid?
    yaml_is_array!(subnet_hashes, "Subnets")
    subnet_hashes.each do |subnet_hash|
      subnet = cloud.subnets.create!(subnet_attributes(subnet_hash))
      build_instances(subnet, subnet_hash["Instances"])
    end
  end

  def subnet_attributes(hash)
    raise InvalidYAMLError, "cloud is not a hash" unless hash.respond_to?(:map)
    {
      name: hash["Name"],
      cidr_block: hash["CIDR_Block"],
      internet_accessible: hash["Internet_Accessible"]
    }
  end

  def build_instances(subnet, instance_hashes)
    return if instance_hashes.nil? || subnet.invalid?
    yaml_is_array!(instance_hashes, "Instances")
    instance_hashes.each do |instance_hash|
      subnet.instances.create!(instance_attributes(instance_hash))
    end
  end

  def instance_attributes(hash)
    raise InvalidYAMLError, "instance is not a hash" unless hash.respond_to?(:map)
    {
      name: hash["Name"],
      ip_address: hash["IP_Address"],
      ip_address_dynamic: hash["IP_Address_Dynamic"],
      internet_accessible: hash["Internet_Accessible"],
      os: hash["OS"],
      uuid: generate_uuid,
      roles: roles_from_names(hash["Roles"])
    }
  end

  def roles_from_names(*names)
    names.map { |n| @scenario.roles.find_or_create_by(name: n) }
  end

  def build_groups
    return if yaml["Groups"].nil?
    yaml_is_array!(yaml["Groups"], "Groups")
    yaml["Groups"].each do |group_hash|
      group = @scenario.groups.create!(group_attributes(group_hash))
      build_players(group, group_hash["Users"])
      build_instance_groups(group, group_hash["Access"])
    end
  end

  def group_attributes(hash)
    {
      name: hash["Name"],
      instructions: hash["Instructions"]
    }
  end

  def build_players(group, player_hashes)
    return if player_hashes.nil?
    yaml_is_array!(player_hashes, "Users")
    player_hashes.each do |player_hash|
      group.players.create!(player_attributes(player_hash))
    end
  end

  def player_attributes(hash)
    user_id = hash["Id"] if User.find_by_id(hash["Id"]).try(:is_student?)
    user_id ||= nil
    {
      login: hash["Login"],
      password: hash["Password"],
      user_id: user_id
    }
  end

  def build_instance_groups(group, access)
    return if access.nil?
    yaml_is_array!(access, "Access")
    access.each do |instance_group_hash|
      group.instance_groups.create!(instance_group_attributes(instance_group_hash))
    end
  end

  def instance_group_attributes(hash)
    {
      instance: @scenario.instances.find_by_name(hash["Instance"]),
      administrator: hash["Administrator"],
      ip_visible: hash["IP_Visible"]
    }
  end

  def build_questions
    # TODO
  end

  def generate_uuid
    `uuidgen`.chomp
  end

  def yaml_is_array!(array, item_name)
    unless array.respond_to?(:each)
      raise InvalidYAMLError, "\"#{item_name}\" must be an array"
    end
  end

  class LoaderComponent
    def initialize(yaml, parent=nil)
      @yaml = yaml
      @parent = parent  # a scenario to attach to for clouds, a cloud for subnets, etc
    end

    def fire!
      return nil unless @yaml && @parent.is_a?(parent_type)
      create!
    end

    private

    def parent_type
      # meant to be overidden
      Object
    end

    def create!
      # meant to be overidden
      nil
    end
  end

  class RoleLoader < LoaderComponent
    private

    def parent_type

    end

    def create!
      # overrides LoaderComponent#create! (see above)
      yaml_is_array!(@yaml, "Roles")  # throws InvalidYAMLError if @yaml isn't an array
      @yaml.each { |hash| @parent.roles.create!(role_attributes(role_hash)) }
    end

    def attributes(hash)
      raise InvalidYAMLError, "role is not a hash" unless hash.respond_to?(:map)
      {
        name: hash["Name"],
        packages: hash["Packages"],
        recipes: recipes_from_names(hash["Recipes"])
      }
    end

    def recipes_from_names(names)
      raise InvalidYAMLError, "\"Recipes\" is not an array" unless names.respond_to?(:map)
      names.map { |n| @parent.recipes.find_or_create_by(name: n) }
    end
  end
end
