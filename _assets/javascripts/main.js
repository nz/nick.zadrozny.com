//= require modernizr-2.6.2-respond-1.1.0.min
//= javascript modernizr-2.6.2-respond-1.1.0.min
//= javascript jquery-1.8.3.min
//= javascript bootstrap.min
//= javascript jquery.infinitescroll
//= javascript turbolinks

$(function() {

  console.log("initializing infinite scroll");
  $('.posts').infinitescroll({
    // selector for the paged navigation (it will be hidden)
    navSelector  : ".pagination",
    // selector for the NEXT link (to page 2)
    nextSelector : ".pagination a.prev",
    // selector for all items you'll retrieve
    itemSelector : ".posts > .post",
    // higher buffer makes the next page load sooner
    bufferPx     : 400,
    donetext     : "Congratulations, stalker! You have just read my entire blog ;-)" ,
  });

})()

