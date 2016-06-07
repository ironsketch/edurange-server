class StatisticsController < ApplicationController
  before_action :authenticate_admin_or_instructor
  before_action :set_statistic, only: [
    :show,
    :destroyme,
    :download_instance_user_bash_history,
    :download_instance_exit_statuses,
    :download_instance_script_logs,
    :download_all,
    :generate_analytics,
    :instance_users
  ]

  require 'rubygems'
  require 'zip'
  require 'tempfile'
  require 'json'

  def index
    # view for all statistics
    @statistics = []
    if @user.is_admin?
      @statistics = Statistic.all
    else
      @statistics = Statistic.where(user_id: current_user.id)
    end
  end

  # GET /statistic/<id>
  def show
    if Scenario.find_by_id(@statistic.scenario_id)
      @statistic.data_fetch_and_process
    end

    @instance_names = @statistic.instance_names
    @instance_first_users = []
    if @instance_names.first
      @instance_first_users = @statistic.instance_user_names(@instance_names.first)
    end
  end
  
  # GET /statistic/<id>/destroyme
  def destroyme
    @statistic.destroy
    if @statistic.destroy
      respond_to do |format|
        format.js { render js: "window.location.pathname='/statistics'" }
      end
    end
  end


  # GET /statistic/1/download_all
  def download_all
    # @statistics = []
    # if @user.is_admin?
    #   @statistics = Statistic.all
    # else
    #   @statistics = Statistic.where(user_id: current_user.id)
    # end

    # folder = "#{Rails.root}/data/statistics/"
    # input_filepaths = []
    # input_filenames = []
    # @statistics.each do |statistic|
    #   # add bash histories
    #   file_path = "#{Rails.root}/data/statistics/#{statistic.id}_Statistic_#{statistic.scenario_name}.txt"
    #   file_name = "#{statistic.id}_Statistic_#{statistic.scenario_name}.txt"
    #   if File.exist?(file_path)
    #     input_filepaths.push(file_path)
    #     input_filenames.push(file_name)
    #   end
    #   # add exit statuses
    #   exit_status_path = "#{Rails.root}/data/statistics/#{statistic.id}_Exit_Status_#{statistic.scenario_name}.txt"
    #   exit_status_name = "#{statistic.id}_Exit_Status_#{statistic.scenario_name}.txt"
    #   if File.exist?(exit_status_path)
    #     input_filepaths.push(exit_status_path)
    #     input_filenames.push(exit_status_name)
    #   end
    #   # add script logs
    #   script_log_path = "#{Rails.root}/data/statistics/#{statistic.id}_Script_Log_#{statistic.scenario_name}.txt"
    #   script_log_name = "#{statistic.id}_Script_Log_#{statistic.scenario_name}.txt"
    #   if File.exist?(script_log_path)
    #     input_filepaths.push(script_log_path)
    #     input_filenames.push(script_log_name)
    #   end
    # end
    #create a temporary zip file
    # temp_file = Tempfile.new("statistics.zip")
    # begin
    #   #Initialize the temp file as a zip file
    #   Zip::OutputStream.open(temp_file) { |zos| }

    #   Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
    #     input_filenames.each do |filename|
    #       zipfile.add(filename, folder + filename)
    #     end
    #   end
    #   #Read the binary data from the file
    #   zip_data = File.read(temp_file.path)
    #   send_data(zip_data, :type => 'application/zip', :filename => "statistic_data.zip")
    # ensure
    #   #close and delete the temp file
    #   temp_file.close
    #   temp_file.unlink
    # end
    send_data(@statistic.data_all_as_zip, :type => 'application/zip', :filename => "statistic_data.zip")
  end

  def download_instance_user_bash_history
    path = @statistic.data_instance_user_bash_history_path(params[:instance_name], params[:user_name])
    if File.exists? path
      send_file(
        path,
        filename: @statistic.data_instance_user_bash_history_download_name(params[:instance_name], params[:user_name]),
        type: "application/txt"
      )
    else
      send_data(
        "No Data: Instance never booted\n",
        filename: @statistic.data_instance_user_bash_history_download_name(params[:instance_name], params[:user_name]),
        type: "application/txt"
      )
    end
  end

  def download_instance_exit_statuses
    send_file(
      @statistic.data_instance_exit_statuses_path(params[:instance_name]),
      filename: @statistic.data_instance_exit_statuses_download_name(params[:instance_name]),
      type: "application/txt"
    )
  end

  def download_instance_script_logs
    send_file(
      @statistic.data_instance_script_logs_path(params[:instance_name]),
      filename: @statistic.data_instance_script_logs_download_name(params[:instance_name]),
      type: "application/txt"
    )
  end


  # method called via AJAX request, sends javascript response after performing analytics  
  def generate_analytics
    output = ""
    cf = nil
    js = ""

    if params[:instances] != "null" and params[:users] != ""
      cf = @statistic.command_frequency(params[:instances], params[:users])
      bh = @statistic.bash_history_instance_user(params[:instances], params[:users])
      yml = YAML.load_file(@statistic.data_instance_user_bash_history_path(params[:instances], params[:users]))
      yml.each do |time, command|
        output += Time.at(time.to_i).strftime("%I:%M %p") + "<br>" + command + "<br>"
      end
      js = "$('#analytic-header').text('Command Frequency: #{params[:users]}');" +
      js = "$('#bash-history-header').text('Bash History: #{params[:users]}');" +
           "new Chartkick.ColumnChart('chart', #{cf.to_json});" +
           "$('#bash-history-instance-user').html(\"#{output}\");"
    end

    respond_to do |format|
      format.js{ render js: js }
    end
  end

  def instance_users
    instance_names = @statistic.instance_user_names(params[:instance]).to_json
    respond_to do |format|
      format.js{ render js: "instance_user_names_set(#{instance_names}, #{@statistic.id});" }
    end
  end

  private

    def set_statistic
      @statistic = Statistic.find(params[:id])
      if not @user.owns? @statistic
        head :ok, content_type: "text/html"
        return
      end
    end

end
