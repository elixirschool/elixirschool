//= require jquery.min.js
//= require util.js
(function($) {
  var cookie = $.getCookie('elixirschooltheme');
  if ( cookie == 'dark' ) {
    $('link[href^="/assets/main"]').remove();
  } else {
    $('link[href^="/assets/dark"]').remove();
  }
})(jQuery)