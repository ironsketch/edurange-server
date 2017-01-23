module YmlRecord
  # Returns an array of [filename, scenario name, description]
  def self.yml_headers(location, user)
    output = []

    if location == 'custom'
      if not File.exists?(Rails.root + "scenarios/custom")
        FileUtils.mkdir(Rails.root + "scenarios/custom")
      end
      path = Rails.root + "scenarios/custom/#{user.id}"
    else
      path = Rails.root + "scenarios/#{location}"
    end

    if not File.exists? path
      FileUtils.mkdir path
    end

    Dir.foreach(path) do |filename|
      next if filename == '.' or filename == '..'
      filepath = "#{path}/#{filename}/#{filename}.yml"
      if File.exists? filepath
        file = YAML.load_file(filepath)
        output.push( { filename: filename, name: file["Name"], description: file["Description"], location: location } )
      end
    end
    return output
  end

  def self.yml_headers_user(user)
    output = []
    Dir.foreach(Rails.root + "scenarios/user/#{user.id}") do |filename|
      next if filename == '.' or filename == '..'
      file = YAML.load_file(Rails.root + "scenarios/user/#{user.id}/#{filename}/#{filename}.yml")
      output.push( { filename: filename, name: file["Name"], description: file["Description"] } )
    end
    return output
  end
end
