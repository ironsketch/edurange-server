# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $('.form_datetime').datetimepicker({
    autoclose: true,
    todayBtn: false,
    pickerPosition: "bottom-left",
    format: 'yyyy-mm-dd hh:00',
    minView: 1,
    todayHighlight: true,
  });
  

initialize_calendar = undefined
initialize_calendar = ->
  $('.calendar').each ->
    calendar = $(this)
    calendar.fullCalendar
      customButtons: newEvent:
        text: 'Schedule Scenario'
        click: ->
          $.getScript '/schedules/new', ->
          return
      header:
        left: 'prevYear,prev,next,nextYear today'
        center: 'title'
        right: 'newEvent month,basicWeek'
      fixedWeekCount: false
      aspectRatio: 1.85
      timezone: false
      selectable: true
      selectHelper: true
      eventLimit: false
      events: '/schedules.json'
      select: (start, end) ->
        $.getScript '/schedules/new', ->
          $('#schedule_start_time').val moment(start).format('YYYY-MM-DD HH:mm')
          $('#schedule_end_time').val moment(end).format('YYYY-MM-DD HH:mm')
          return
        calendar.fullCalendar 'unselect'
        return
      eventClick: (event, jsEvent, view) ->
        $.getScript event.show_url, ->
        return
    return
  return

$(document).on 'turbolinks:load', initialize_calendar