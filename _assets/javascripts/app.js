/*
 *= require jquery
 *= require toc.js
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
  $('#toc').toc({
    listType: 'ul',
    title: '',
    headers: 'h1, h2, h3:not([id="social"]), h4, h5, h6',
    noBackToTopLinks: true,
    minimumHeaders: 0
  });
});