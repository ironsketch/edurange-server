# This file is included in {Scenario}, {Cloud}, {Subnet} and {Instance}. Essentialy it has glue code for
# both defining methods dynamically (within concerns such as Aws that handle provider specific API calls) as well as
# routing those methods (within {#method_missing})
# Apart from defining these methods, the only other role this file has is to declare the "status" column, an integer corresponding to
# three states stored in the local database. They can be :stopped, :booting, or :booted. All files which include {Provider} receive this,
# and helper methods to retrieve the database state. Check out enum in Rails.
# When reading through this file (and other Concerns), think of the file including them as their "self". When a {Cloud} includes this file,
# any of these methods "self" will refer to that {Cloud cloud}.
module Provider
  extend ActiveSupport::Concern
  
  included do
    enum status: [
      :stopped,
      :boot_scheduled,
      :booting,
      :boot_fail,
      :booted,
      :booted_partial,
      :pausing,
      :paused,
      :pause_error,
      :starting,
      :start_error,
      :unboot_scheduled,
      :unbooting,
      :unboot_fail,
    ]
  end

  # Debug

  def debug(options, message)
    return if options == {}
    
    if options[:console_print]
      if message.size > 0
        pad = message[0] == " " ? nil : " "
      end
      puts "#{self.name}:#{pad}#{message}"
      STDOUT.flush
    end

    File.open("#{data_boot_file(options)}", "a+") { |f| f.write("#{self.name}: #{message}\n") }
  end

  def data_boot_file(options)
    "#{self.scenario.statistic.data_path_boot}/#{options[:boot_id]}"
  end

  def data_boot_file_read(options)
    File.open("#{data_boot_file(options)}", "r") { |f| puts f.read() }
  end

  def clear_log
    self.update_attribute(:log, '')
  end

  #############################################################
  #  Booting

  def boot(options = {})
    self.class == Scenario ? self.boot_scenario(options) : self.boot_single(options)
  end

  def boot_all(pretend, background, console_print)
    options = { resources: {} }
    self.descendents.each do |r|
      options[:resources][r.name] = {}
      options[:resources][r.name][:action] = :boot
      options[:resources][r.name][:pretend] = pretend
      options[:resources][r.name][:background] = background
    end
    options[:console_print] = console_print
    background ? self.delay(queue: self.class.to_s.downcase).boot(options) : self.boot(options)
  end

  def unboot_all(pretend, background, console_print)
    options = { resources: {} }
    self.descendents.each do |r|
      options[:resources][r.name] = {}
      options[:resources][r.name][:action] = :unboot
      options[:resources][r.name][:pretend] = pretend
      options[:resources][r.name][:background] = background
    end
    options[:console_print] = console_print
    background ? self.delay(queue: self.class.to_s.downcase).boot(options) : self.boot(options)
  end

  def boot_single(action, pretend, background, console_print)

    err = []
    err << 'scenario can not be booted solo' if self.class == Scenario
    err << 'action must be :boot or :unboot' if not (action == :boot or action == :unboot)
    err << 'pretend must be true or false' if not (pretend.class == TrueClass or pretend.class == FalseClass)
    err << 'background must be true or false' if not (background.class == TrueClass or background.class == FalseClass)
    err << 'console_print must be true or false' if not (console_print.class == TrueClass or console_print.class == FalseClass)
    
    if action == :boot
      err << 'parent must booted, booting, or scheduled to boot and self must be stopped' if not self.bootable?
    elsif action == :unboot
      err << 'children must stopped, unbooting, or scheduled to unboot and self must be booted' if not self.unbootable?
    end

    options = { 
      resources: { 
        self.name => {
          action: action,
          pretend: pretend,
          background: background
        }
      },
      console_print: console_print, 
      boot_id: Time.now.strftime("%y-%m-%d-%s") + '-' + `uuidgen`[0..6],
      boot_code: `uuidgen`.chomp,
      single: true
    }

    raise "error: #{err}" if err.any?

    debug options, "#{action} status: #{self.status} boot code: #{self.boot_code} options: #{options}"

    # schedule descendents, fail if some other boot process schedules them first
    debug options, "scheduling" 

    if options[:resources][self.name][:action] == :boot
      result = self.class.where("id = ? AND status = ? AND boot_code = ?", 
        self.id, 
        self.class.statuses[:stopped],
        ""
      ).update_all(status: self.class.statuses[:boot_scheduled], boot_code: options[:boot_code])
      puts "result: #{result}"
    elsif options[:resources][self.name][:action] == :unboot
      result = self.class.where("id = ? AND status = ? AND boot_code = ?", 
        self.id, 
        self.class.statuses[:booted],
        ""
      ).update_all(status: self.class.statuses[:unboot_scheduled], boot_code: options[:boot_code]) > 0
    end
    self.reload

    raise "could not schedule. boot code: #{self.boot_code}" if not result
    
    options[:resources][self.name][:background] ? self.delay(queue: self.class.to_s.downcase).boot_descendent(options) : boot_descendent(options)
  rescue => e
    self.errors.add(:boot, e.message.to_s)
  end

  # Scenario methods

  def boot_scenario(options)
    options[:boot_id] = Time.now.strftime("%y-%m-%d-%s") + '-' + `uuidgen`[0..6]
    debug options, "try boot. status:#{self.resources_status_hash}"

    # check for correct options and that everything can boot
    boot_scenario_options_validate(options)

    # try and enter boot
    boot_lock(options)

    # schedule descendents
    boot_scenario_schedule_descendents(options)

    # boot descendents
    boot_scenario_descendents(options)

    # wait for descendents to finish
    boot_scenario_descendents_wait(options)

    boot_scenario_done(options)

    return data_boot_file_read(options)
  rescue => e
    
    # debug options, "FAILED #{e.message.to_s}"
    debug options, "FAILED #{e.message.to_s} #{e.backtrace}"
    errors.add(:boot, e.message.to_s)

    # wait for all resources to reach failed state then release
    self.reload
    self.descendents_boot_in.each do |d|
      debug options, "waiting for #{d.name} to finish"

      until (d.booted? or d.boot_fail?)
        sleep 1
        d.reload
      end

      if d.boot_fail?
        d.update_attribute(:status, :stopped)
      elsif d.unboot_fail?
        d.update_attribute(:status, :booted)
      end

      d.update_attribute(:boot_code, "")
    end

    # recheck status
    self.status_update
    debug options, "#{self.resources_status_hash}"

    # print if necessary
    if options[:console_print] and options[:background]
      puts data_boot_file_read(options)
    end

    # releaes self
    self.update_attribute(:boot_code, "")
    return data_boot_file_read(options)
  end

  def boot_scenario_options_validate(options)
    debug options, "validating boot options:#{options}"

    err = []
    # check for no options
    raise "options must not be emtpy" if options.empty?
    options[:background] = false if not options.has_key?(:background)
    options[:console_print] = false if not options.has_key?(:console_print)
    options[:single] = false if not options.has_key?(:single)

    # check for non valid resource
    options[:resources].each do |k, v|
      err << "invalid resource in options '#{k}'" if not self.resource(k)
      err << "must specifiy background true or false in options" if not options[:resources][k].has_key?(:background)
      err << "must specifiy pretend true or false in options" if not options[:resources][k].has_key?(:pretend)
    end
    raise err.to_s if err.any?

    # get relations and statuses
    relations = self.descendents_relations

    # set relations to what they would be after boot
    options[:resources].each do |k, v|
      next if k == :console_print or k == :boot_id
      if options[:resources][k][:action] == :boot
        # resources must be stooped to boot
        if relations[k][:status] != "stopped"
          err << "resource #{k} must be stopped to boot."
        else
          relations[k][:status] = "booted"
        end
      elsif options[:resources][k][:action] == :unboot
        if relations[k][:status] != "booted"
          err << "resource #{k} must be booted to stop."
        else
          relations[k][:status] = "stopped"
        end
      end
    end

    # check that post-boot relations are valid
    relations.each do |k, v|
      if relations[k][:parent_class] != "Scenario"
        if relations[k][:status] == "booted" and (relations[relations[k][:parent]][:status] != "booted")
          err << "resource #{k} parent must be booted, booting or scheduled to boot #{relations}"
        end

        if relations[k][:status] == "stopped" and relations[k][:children].select { |c| relations[c][:status] == "booted" }.any?
          err << "resource #{k} chidren must be stopped, unbooting or scheduled to unboot"
        end
      end
    end

    options[:boot_code] = ""
    options[:timeout] = 60*4

    raise err.to_s if err.any?
  end

  def boot_lock(options)
    self.debug options, "getting boot lock"

    if self.class == Scenario
      fail = self.class.where("id = ? AND (status = ? OR status = ? OR status = ?) AND boot_code = ?", 
        self.id, 
        self.class.statuses[:stopped],
        self.class.statuses[:booted],
        self.class.statuses[:booted_partial], 
        options[:boot_code]
      ).update_all(status: self.class.statuses[:booting]) <= 0
      if fail
        self.reload
        raise "#{self.name} status:#{self.status} boot_code: '#{self.boot_code}' must be stopped, booted or booted partial, have boot code: '#{self.boot_code}' and be the only process currently booting this resource"
      end
    else
      if options[:resources][self.name][:action] == :boot
        fail = self.class.where("id = ? AND (status = ? OR status = ? OR status = ?) AND boot_code = ?", 
          self.id, 
          self.class.statuses[:stopped], 
          self.class.statuses[:booted_partial], 
          self.class.statuses[:boot_scheduled], 
          options[:boot_code]
        ).update_all(status: self.class.statuses[:booting]) <= 0
        if fail
          self.reload
          raise "#{self.name} status:#{self.status} boot_code: '#{self.boot_code}' must be stopped to boot, have boot code: '#{self.boot_code}' and be the only process currently booting this resource"
        end
      elsif options[:resources][self.name][:action] == :unboot
        fail = self.class.where("id = ? AND (status = ? OR status = ? OR status = ?) AND boot_code = ?", 
          self.id, 
          self.class.statuses[:booted], 
          self.class.statuses[:booted_partial], 
          self.class.statuses[:unboot_scheduled], 
          options[:boot_code]
        ).update_all(status: self.class.statuses[:unbooting]) <= 0
        if fail
          self.reload
          raise "#{self.name} status:#{self.status} boot_code: '#{self.boot_code}' must be booted to unboot, have boot code: '#{self.boot_code}' and be the only process currently unbooting this resource"
        end
      end
    end
  end

  def boot_scenario_schedule_descendents(options)

    # set boot code
    options[:boot_code] = `uuidgen`.chomp
    self.update_attribute(:boot_code, options[:boot_code])

    # check if nothing will be booted
    if self.descendents.select { |d| options[:resources][d.name][:action] == :none }.size == self.descendents.size
      raise 'nothing scheduled to boot.'
    end

    # schedule descendents, fail if some other boot process schedules them first
    self.descendents.select { |d| options[:resources][d.name][:action] != :none }.each do |descendent|
      if options[:resources][descendent.name][:action] == :boot
        result = descendent.class.where("id = ? AND status = ?", 
          descendent.id, 
          descendent.class.statuses[:stopped]
        ).update_all(status: descendent.class.statuses[:boot_scheduled], boot_code: options[:boot_code]) > 0
      elsif options[:resources][descendent.name][:action] ==:unboot
        result = descendent.class.where("id = ? AND status = ?", 
          descendent.id, 
          descendent.class.statuses[:booted]
        ).update_all(status: descendent.class.statuses[:unboot_scheduled], boot_code: options[:boot_code]) > 0
      end

      if result
        descendent.reload
      else
        debug options, "could not schedule #{descendent.name}"
        raise 'could not schedule all dependents.'
      end
    end

    # scheduled children
    debug options, "scheduled #{self.descendents_boot_scheduled_names}" if self.descendents_boot_scheduled.any?
  end

  def boot_scenario_descendents(options)

    self.descendents_boot_scheduled_descending.select { |d| options[:resources][d.name][:action] == :boot }.each do |descendent|
      debug options, "booting '#{descendent.name}' background:#{options[:resources][descendent.name][:background]}"
      options[:resources][descendent.name][:background] ? descendent.delay(queue: descendent.class.to_s.downcase).boot_descendent(options) : descendent.boot_descendent(options)
      self.reload
    end

    self.descendents_boot_scheduled_ascending.select { |d| options[:resources][d.name][:action] == :unboot }.each do |descendent|
      debug options, "booting '#{descendent.name}' background:#{options[:resources][descendent.name][:background]}"
      options[:resources][descendent.name][:background] ? descendent.delay(queue: descendent.class.to_s.downcase).boot_descendent(options) : descendent.boot_descendent(options)
      self.reload
    end
  end

  def boot_scenario_descendents_wait(options)

    # wait for every descendent to be done
    self.descendents_boot_in.each do |d|
      debug options, "waiting for descendent \"#{d.name}\" status:#{d.status} boot_code:#{d.boot_code} to finish"
      (sleep 1; d.reload) until d.boot_done?
    end

    # stop any failed 
    self.descendents_boot_in.each do |d|
      if d.boot_fail?
        debug options, "descendent \"#{d.name}\" boot failed"
        self.errors.add(:boot, "#{self.name} descendent \"#{d.name}\" boot failed #{d.status}")
        d.set_stopped
      end
      if d.unboot_fail?
        debug options, "descendent \"#{d.name}\" unboot failed"
        self.errors.add(:boot, "#{self.name} descendent \"#{d.name}\" unboot failed")
        d.set_booted
      end
    end

    self.reload
  rescue => e
    raise "timeout waiting for descendents to boot: #{self.descendents_boot_scheduled_names}"
  end

  def boot_scenario_done(options)
    debug options, "DONE status:#{self.resources_status_hash}"
    self.update_attribute(:boot_code, "")
  end

  # Descendent methods

  def boot_descendent(options)
    # try and enter boot
    self.boot_lock(options)

    # check if bootable
    self.boot_descendent_check_bootable_unbootable(options)

    # wait if necessary
    self.boot_descendent_debug_wait(options) if options[:resources][self.name].has_key?(:wait)

    # wait for parent to finish
    self.boot_descendent_wait_for_parent_or_children(options)

    # do class specific booting tasks
    self.boot_descendent_main(options)

    # check for errors
    self.boot_descendent_error_check(options)

    # success
    self.boot_descendent_success(options)
  rescue => e
    if options[:single] == true
      debug options, "error: #{e.message}"
      self.update_attribute(:status, :stopped)
      self.update_attribute(:boot_code, '')
    else
      self.boot_descendent_failure(e, options)
    end
  end

  def boot_descendent_check_bootable_unbootable(options)
    if options[:resources][self.name][:action] == :boot
      raise "parent \"#{self.parent.name}\" status:\"#{self.parent.status}\" needs to be booted or booting" if not self.bootable?
    elsif options[:resources][self.name][:action] == :unboot
      raise "parent \"#{self.parent.name}\" status:\"#{self.parent.status}\" needs to be booted or booting" if not self.unbootable?
    end
  end

  def boot_descendent_debug_wait(options)
    debug options, "debug waiting #{options[:resources][self.name][:wait]}s"
    sleep options[:resources][self.name][:wait]
  end

  def boot_descendent_wait_for_parent_or_children(options)

    if options[:resources][self.name][:action] == :boot
      return if self.parent.class == Scenario
      debug options, "waiting up to #{options[:timeout]}s for parent \"#{self.parent.name}\" to #{options[:resources][self.name][:action].to_s}" if not self.parent.boot_done?

      if not self.parent.boot_done?
        Timeout.timeout(options[:timeout]) { sleep 1 while not self.parent.boot_done? }
      end
      self.reload
      raise "#{self.name} parent #{self.parent.name} failed returning now" if self.parent.boot_fail?

    elsif options[:resources][self.name][:action] == :unboot
      return if self.class == Instance
      debug options, "waiting up to #{options[:timeout]}s for children \"#{self.children.map { |c| c.name }}\" to boot" if self.children_booting?
      if self.children_booting?
        Timeout.timeout(options[:timeout]) { sleep 1 while self.children_booting? }
      end
      self.reload
      raise "#{self.name} children #{self.children.select { |c| c.unboot_fail? }.map { |c| c.name}} failed returning now" if self.children.select { |c| c.unboot_fail? }.any?

    end
  rescue => e
    raise
  rescue Timeout::Error => e
    raise "timeout waiting for parent #{self.parent.name} to boot."
  end

  def boot_descendent_main(options)
    if options[:resources][self.name][:pretend]
      raise 'test error failed on purpose' if options[:resources][self.name][:fail]
    else
      self.send("#{Rails.configuration.x.provider}_#{self.class.to_s.downcase}_#{options[:resources][self.name][:action].to_s}", options)
    end
  end

  def boot_descendent_error_check(options)
    if self.errors.any?
      debug options, "failure detected #{self.errors.messages}- cleaning up"
      raise "#{options[:resources][self.name][:action].to_s} failed"
    end
  end

  def boot_descendent_success(options)
    if options[:resources][self.name][:action] == :boot
      self.set_booted
    elsif options[:resources][self.name][:action] == :unboot
      self.set_stopped
      self.update_attribute(:driver_id, nil)
    end
    debug options, "#{options[:resources][self.name][:action].to_s} successful"
    result = self.update_attribute(:boot_code, "")
  end

  def boot_descendent_failure(e, options)
    if options[:resources][self.name][:action] == :boot
      self.set_boot_fail
    elsif options[:resources][self.name][:action] == :unboot
      self.set_unboot_fail
    end
    debug options, "FAILURE: #{e.message.to_s} #{e.backtrace}"
    # debug options, "FAILURE: #{e.message.to_s}"
  end

  def pause
    if not (self.class == Instance or self.class == Scenario)
      return
    end

    if not self.booted?
      errors.add(:boot, "must be booted to pause")
      return
    end
    
    if self.class == Scenario
      self.set_pausing
      self.delay(queue: self.class.to_s.downcase).send("provider_pause_#{self.class.to_s.downcase}")
    else
      self.send("provider_pause_#{self.class.to_s.downcase}")
    end
  end

  def start
    if not (self.class == Instance or self.class == Scenario)
      return
    end

    if not self.paused?
      errors.add(:boot, "must be paused to start")
      return
    end

    if self.class == Scenario
      self.set_starting
      self.delay(queue: self.class.to_s.downcase).send("provider_start_#{self.class.to_s.downcase}")
    else
      self.send("provider_start_#{self.class.to_s.downcase}")
    end
  end

  # Relations 

  def family
    self.ancestors + [self] + self.descendents
  end

  def children
    arr = []
    arr += self.clouds if self.class == Scenario
    arr += self.subnets if self.class == Cloud
    arr += self.instances if self.class == Subnet
    arr
  end

  def children_booting?
    self.children.select { |c| not c.boot_done? }.any?
  end

  def descendents
    arr = []
    arr += self.clouds if self.class == Scenario
    arr += self.subnets if [Scenario,Cloud].include? self.class
    arr += self.instances if [Scenario,Cloud,Subnet].include? self.class
    arr
  end

  def parent
    return nil if self.class == Scenario
    return self.scenario if self.class == Cloud
    return self.cloud if self.class == Subnet
    return self.subnet if self.class == Instance
  end

  def ancestors
    arr = []
    arr << self.scenario if [Instance,Subnet,Cloud].include? self.class
    arr << self.cloud if [Instance,Subnet].include? self.class
    arr << self.subnet if self.class == Instance
    arr
  end

  def descendents_relations
    hash = {}
    self.descendents.each do |d|
      hash[d.name] = {}
      hash[d.name][:class] = d.class.to_s
      hash[d.name][:status] = d.status
      hash[d.name][:parent] = d.parent ? d.parent.name : nil
      hash[d.name][:parent_class] = d.parent ? d.parent.class.to_s : nil
      hash[d.name][:children] = d.children.map { |d| d.name }
    end
    hash
  end

  def descendents_status_relations
    hash = {}
    self.descendents.each do |d|
      hash[d.name] = {}
      hash[d.name][:class] = d.class.to_s
      hash[d.name][:status] = d.status
      hash[d.name][:parent] = d.parent ? d.parent.name : nil
      hash[d.name][:parent_class] = d.parent ? d.parent.class.to_s : nil
      hash[d.name][:children] = d.children.map { |d| d.name }
    end
    hash
  end

  def descendents_boot_in
    self.reload
    self.descendents.select { |d| d.boot_code == self.boot_code and self.boot_code != "" }
  end

  def descendents_boot_scheduled
    self.reload
    self.descendents.select { |d| ((d.boot_scheduled? or d.unboot_scheduled?) and (d.boot_code == self.boot_code)) }
  end

  def descendents_boot_scheduled_descending
    self.reload
    d = []
    d += self.descendents.select { |d| d.class == Cloud and ((d.boot_scheduled? or d.unboot_scheduled?) and (d.boot_code == self.boot_code)) }
    d += self.descendents.select { |d| d.class == Subnet and ((d.boot_scheduled? or d.unboot_scheduled?) and (d.boot_code == self.boot_code)) }
    d += self.descendents.select { |d| d.class == Instance and ((d.boot_scheduled? or d.unboot_scheduled?) and (d.boot_code == self.boot_code)) }
    d
  end

  def descendents_boot_scheduled_ascending
    self.reload
    d = []
    d += self.descendents.select { |d| d.class == Instance and ((d.boot_scheduled? or d.unboot_scheduled?) and (d.boot_code == self.boot_code)) }
    d += self.descendents.select { |d| d.class == Subnet and ((d.boot_scheduled? or d.unboot_scheduled?) and (d.boot_code == self.boot_code)) }
    d += self.descendents.select { |d| d.class == Cloud and ((d.boot_scheduled? or d.unboot_scheduled?) and (d.boot_code == self.boot_code)) }
    d
  end

  def descendents_boot_scheduled_names
    self.descendents.select { |d| ((d.boot_scheduled? or d.unboot_scheduled?) and (d.boot_code == self.boot_code)) }.map { |d| d.name }
  end

  def resource(name)
    self.descendents.each do |d|
      return d if d.name == name
    end
    nil
  end

  def resources_status_hash
    self.reload
    a = { self.name => self.status }
    self.descendents.each { |d| a = a.merge({ d.name => d.status}) }
    a
  end

  def boot_done?
    self.reload
    (self.stopped? or self.boot_fail? or self.unboot_fail? or self.booted?)
  end

  def bootable?
    if self.class == Scenario
      return self.descendents.select { |d| d.stopped? }.any?
    end
    return false if not (self.stopped? or self.booting? or self.boot_scheduled?)
    return true if self.class == Cloud
    return (self.parent.boot_scheduled? or self.parent.booting? or self.parent.booted?)
  end

  def unbootable?
    if self.class == Scenario
      return self.descendents.select { |d| d.booted? }.any?
    end
    return false if not (self.booted? or self.unbooting? or self.unboot_scheduled?)
    return true if self.class == Instance
    return (not self.children.select { |c| c.booted? }.any?)
  end

  #############################################################
  #  Status set and get

  def set_stopped
    self.update_attribute(:status, :stopped)
    self.scenario.status_update if self.class != Scenario
  end

  def set_booting
    self.update_attribute(:status, :booting)
    self.scenario.status_update if self.class != Scenario
  end

  def set_boot_fail
    self.update_attribute(:status, :boot_fail)
    self.scenario.status_update if self.class != Scenario
  end

  def set_booted
    self.update_attribute(:status, :booted)
    self.scenario.status_update if self.class != Scenario
  end

  def set_paused
    self.update_attribute(:status, :paused)
    self.scenario.status_update if self.class != Scenario
  end

  def set_pausing
    self.update_attribute(:status, :pausing)
    self.scenario.status_update if self.class != Scenario
  end

  def set_starting
    self.update_attribute(:status, :starting)
    self.scenario.status_update if self.class != Scenario
  end

  def set_unbooting
    self.update_attribute(:status, :unbooting)
    self.scenario.status_update if self.class != Scenario
  end

  def set_unboot_fail
    self.update_attribute(:status, :unboot_fail)
    self.scenario.status_update if self.class != Scenario
  end

  def queued?
    return (self.queued_boot? or self.queued_unboot?)
  end

  # Dynamically calls the method provided, routing it through the provider concern specified at runtime by
  # Settings.driver.
  # @param meth The method to call
  # @param args The arguments to pass
  # @param block Any block arguments to pass
  # @see #run_provider_method
  # @return [nil]
  def method_missing(meth, *args, &block)
    if meth.to_s =~ /^provider_(.+)$/
      run_provider_method($1, *args, &block)
    else
      super
    end
  end

  # Calls the method provided in the EDURange config, defined in the concerns for each Driver at runtime.
  # Currently does not pass arguments.
  # @return [nil]
  def run_provider_method(provider_method, *args, &block)
    self.send("#{Rails.configuration.x.provider}_#{provider_method}".to_sym, *args)
  end
end
