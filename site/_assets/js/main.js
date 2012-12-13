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

