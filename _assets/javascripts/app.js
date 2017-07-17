/*
 *= require jquery
 *= require toc.js
 */

var swap_icon = function(el) {
  el.find('i')
    .toggleClass('icon-chevron-down')
    .toggleClass('icon-chevron-right');
};

var toggle_lessons = function(el) {
  el.children('.sidebar-nav-list').toggle();
};

var toggle_section = function() {
  var parent = $(this).parent();
  swap_icon(parent);
  toggle_lessons(parent);
};

var show_vcs_history = function() {
  var base = 'https://github.com/doomspork/elixir-school/commits/master/lessons/',
      path = window.location
    .toString()
    .split('/')
    .filter(function(e) {
      return "" !== e;
    })
    .slice(-2)
    .join('/');
  window.open(base + path + '.md');
};

$(function() {
  $('.sidebar-nav-header').click(toggle_section);
  $('#toc').toc({
    listType: 'ul',
    title: '',
    headers: 'h1, h2, h3:not([id="social"]), h4, h5, h6',
    noBackToTopLinks: false,
    minimumHeaders: 0,
    backToTopClasses: 'icon icon-chevron-up2 back-to-top'
  });
  $('.version-info').click(show_vcs_history);
});