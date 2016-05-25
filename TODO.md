# Edurange TODO list

## Server

- Scenario script editor

  - User nice editor (google 'CodeMirror')

  - Allow user to specify recipe type (bash/python/ruby/etc)

  - Check syntax

- Create dashboard that shows booted scenarios right away

- Add instructor/student/team instructions to yml (done?)

- Change yml files to yml.erb to be preprocessed in yml for adding ruby functions like random numbers. (done?)

- Save scenario information (bash_histories, answers, etc) in a yml file when scenario is destroyed, place it in the instructors data folder

- Push server

- Packages whitelisting

- Get bash_history in real time through the web client

- Switch database to postgresql

- Create tests

- Get error handling to work in chef. on cookbook error send error message back to instructor machine

- Enable dry run (don't create vpcs/instances, just parse & print debug info)

- Remove com_page from scenario table (done?)

- Fix scenarios not showing for admin (is this still a problem?)

- Implement mailing features. i.e. invite through email to become instructor/student (might be done?)

- Implement scenario pausing

- Implement scenario expiration time (unboot when this time is reached)

## Scenarios

- Create scapyhunt scenario (done?)

- Add more exercises
