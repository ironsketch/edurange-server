$(document).ready(function() {
    $('#instructors-table').DataTable({
        'paging': false,    /* should turn back on if we ever have a ridiculous
                               number of instructors */
        'searching': false,
        'select': true
    });
});
