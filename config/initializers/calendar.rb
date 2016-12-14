# Calendar class keeps track of available aws vpc and instances for the Scheduler model

class Calendar

  # Initialize Calendar
  def self.set_up
    @vpc_limit = Rails.configuration.x.aws[Rails.configuration.x.aws['region']]['vpc_limit']
    @instance_limit = Rails.configuration.x.aws[Rails.configuration.x.aws['region']]['instance_limit']
    @time_slots = Rails.cache.read('time_slots')
    if @time_slots == nil
      @time_slots = Hash.new
    end
  end

  # Checks for existence of necessary hashes - year, month, etc.
  # Creates necessary year and populates all hours in needed months
  def self.check_times(start_time, end_time)
    check_year(end_time)
    check_year(start_time)

    months_count = (end_time.month - start_time.month) % 12
    for next_month in 0..months_count
      check_month(start_time.advance(months: next_month))
    end

    days_count = (end_time.to_i - start_time.to_i) / (60 * 60 * 24)
    for next_day in 0..days_count
      check_day(start_time.advance(days: next_day))
    end
  end

  def self.check_year(time)
    unless @time_slots.has_key?(time.year)
      @time_slots[time.year] = Hash.new
      for months in 1..12
        @time_slots[time.year][months] = Hash.new
      end
    end
  end

  def self.check_month(time)
    if @time_slots[time.year][time.month].empty?
      for days in 1..Time.days_in_month(time.month, time.year)
        @time_slots[time.year][time.month][days] = Hash.new
      end
    end
  end

  def self.check_day(time)
    if @time_slots[time.year][time.month][time.day].empty?
      for hour in 0..23
        @time_slots[time.year][time.month][time.day][hour] = Hash.new
      end
    end
  end


  # Puts scenario and instance_count in all necessary time slots in @time_slots
  def self.schedule_event(user, scenario, instance_count, start_time, end_time)
    hours_between = (end_time - start_time).to_i / (60 * 60)
    for hours_since in 0..hours_between
      this_hour = start_time.advance(hours: hours_since)
      slot = @time_slots[this_hour.year][this_hour.month][this_hour.day][this_hour.hour]
      slot[user.name + " - " + scenario] = instance_count
    end
    Rails.cache.write('time_slots', @time_slots)
  end


  # Checks if there are available resources for every hour in time range
  # If there there is enough resources, calls schedule_event
  def self.check_resources(user, scenario, instance_count, start_time, end_time)
    check_times(start_time, end_time)
    max_space_taken = 0

    full_hours = Array.new

    hours_between = (end_time - start_time).to_i / (60 * 60)
    for hours_since in 0..hours_between
      instances_used = 0;
      vpcs_used = 0;
      this_hour = start_time.advance(hours: hours_since)
      slot = @time_slots[this_hour.year][this_hour.month][this_hour.day][this_hour.hour]
      slot.each do |key, value|
        instances_used += value
        vpcs_used += 1
      end

      if (instances_used + instance_count > @instance_limit) || (vpcs_used + 1 > @vpc_limit)
        full_hours.push(this_hour)
      end
    end

    if full_hours.empty?
      schedule_event(user, scenario, instance_count, start_time, end_time)
      return true
    else
      return false
    end
  end

  # Deletes all of given schedule from @time_slots
  # This is called when a Schedule is deleted
  def self.delete_event(user, scenario, start_time, end_time)
    hours_between = (end_time - start_time).to_i / (60 * 60)
    for hours_since in 0..hours_between
      this_hour = start_time.advance(hours: hours_since)
      slot = @time_slots[this_hour.year][this_hour.month][this_hour.day][this_hour.hour]
      slot.delete(user.name + " - " + scenario)
    end
    Rails.cache.write('time_slots', @time_slots)
  end

  # Helper function to print hash
  def self.print_slots
    return @time_slots
  end
end

Calendar.set_up