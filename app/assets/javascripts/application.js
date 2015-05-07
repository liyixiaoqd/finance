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
//= require jquery_ujs
//= require turbolinks
//= require_tree .

$(document).ready(function(){
  $(".button_clear_time").click(function(){
	form_obj=this.parentNode
	input_objs=form_obj.getElementsByTagName("input")

	for (var i=0;i<input_objs.length;i++){
		if (input_objs[i].name.match(/time$/)) {
			input_objs[i].value=""
		}
	}

	foreach 
  });
});
