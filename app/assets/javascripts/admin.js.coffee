# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

createInstructorModal = () ->
    $('#modal-create-instructor').find('#email').val('');
    $('#modal-create-instructor').find('#name').val('');
    $('#modal-create-instructor').find('#organization').val('');
