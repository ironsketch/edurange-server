// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery.turbolinks
//= require jquery_ujs
//= require dataTables/jquery.dataTables
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require dataTables/extras/dataTables.select
//= require bootstrap
//= require underscore
//= require bootstrap
//= require_tree .
// require turbolinks

function update_flash(message) {
    if (!$('#flash_notice').length) {
        $('main').prepend("<h5 class='alert alert-success'><btn class='btn-default close' type='button' data-dismiss='alert' aria-hidden='true'> x </btn><div id='flash_notice'></div></h5>");
    }
    $('#flash_notice').html(message);
}

$(document).ready(function() {
    table = $('.dataTable').DataTable({
        columnDefs: [ {
            orderable: false,
            searchable: false,
            targets:   0
        } ],
        order: [[ 1, 'asc' ]]
    });

    // Handle click on "Select all" control
    $('#select_all').on('click', function() {
       var rows = table.rows({ 'search': 'applied' }).nodes();
       $(':checkbox', rows).prop('checked', this.checked);
    });

    // Handle click on checkbox to set state of "Select all" control
    $('tbody:checkbox').on('change', function() {
       if (!this.checked) {
          var el = $('#select_all').get(0);
          if(el && el.checked && ('indeterminate' in el)){
             el.indeterminate = true;
          }
       }
    });
});
