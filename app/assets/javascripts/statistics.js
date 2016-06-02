// var request_graph = function(id){
// 	var resource = '/statistics/' + id + '/generate_analytics'
//     var data = {
//     	user : $("#users")[0].value
//     }
//  	$.get(resource, data, function(){
//  		console.log("Sent username to statistics controller.")
//  	});
// }

var instance_users = function(id){
  var resource = '/statistics/' + id + '/instance_users'
    var data = {
      instance : $('#instances option:selected').text()
    }
  $.get(resource, data, function(){
    console.log("Sent username to statistics controller.")
  });
}

function update_button_values(id) {
  name = $('#generate_analytics_form').find('#instances').val();
  user = $('#generate_analytics_form').find('#users').val();

  $('#download_instance_user_bash_history_form').find('#instance_name').attr('value', name);
  $('#download_instance_user_bash_history_form').find('#user_name').attr('value', user);

  $('#download_instance_exit_statuses_form').find('#instance_name').attr('value', name);

  $('#download_instance_script_logs_form').find('#instance_name').attr('value', name);

  var resource = '/statistics/' + id + '/generate_analytics'
    var data = {
      instances : name,
      users: user
    }
  $.post(resource, data, function(){
    console.log("Sent username to statistics controller.")
  });
}

function instance_user_names_set(names, id) {
  s = $("select[name='users']")
  s.empty();
  $(names).each(function(i, name) {
    s.append($("<option>", { value: name, html: name}));
  });

  update_button_values(id);
}