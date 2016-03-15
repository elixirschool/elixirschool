/*
 *= require jquery
 */

var swap_icon = function(el) {
  el.find('i')
    .toggleClass('fa-chevron-down')
    .toggleClass('fa-chevron-right');
};

var toggle_lessons = function(el) {
  el.children('.sidebar-nav-list').toggle();
};

var toggle_section = function() {
  var parent = $(this).parent();
  swap_icon(parent);
  toggle_lessons(parent);
};

$(function() {
  $('.sidebar-nav-header').click(toggle_section);

  $('.advanced .sidebar-nav-header').click();
  $('.specifics .sidebar-nav-header').click();
});
