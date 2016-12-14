date_format = '%Y-%m-%dT%H:%M:%S'

json.id schedule.id
json.title schedule.scenario
json.start schedule.start_time.strftime(date_format)
json.end schedule.end_time.strftime(date_format)

json.edit_url edit_schedule_path(schedule)
json.show_url schedule_path(schedule)