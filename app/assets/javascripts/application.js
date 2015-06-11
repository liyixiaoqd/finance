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
//= require jquery-ui/datepicker

$(document).ready(function(){
  $("#button_clear").click(function(){
	form_obj=this.parentNode.parentNode
	input_objs=form_obj.getElementsByTagName("input")

	for (var i=0;i<input_objs.length;i++){
		// if (input_objs[i].name.match(/time$/)) {
			if(input_objs[i].type=="text")
				input_objs[i].value=""
		// }
	}

	input_objs=form_obj.getElementsByTagName("select")
	for (var i=0;i<input_objs.length;i++){
		input_objs[i].selectedIndex=0
	}
  });

  $("#button_refresh").click(function(){
	location.reload();
  });


  $("#login_button").click(function(){
  	var passwd=document.getElementById("admin_admin_passwd_encryption").value
  	document.getElementById("admin_admin_passwd_encryption").value=hex_md5(passwd)
  });


  $("#button_submit_time").click(function(event){
  	if(document.getElementById("start_time").value=="" || document.getElementById("end_time").value==""){
		alert("请输入开始与结束时间")
		event.preventDefault()
  	}
  });

  $("#link_to_export").click(function(event){
  	input_objs=document.getElementById("index_and_export_form").children
  	var condition="?"
  	var control_index=0
  	var control_len=0
	for (var i=0;i<input_objs.length;i++){
		if(input_objs[i].type=="text"){
			control_len++
			if (input_objs[i].value!=""){
				if (condition=="?")
					condition+=input_objs[i].name+"="+input_objs[i].value
				else
					condition+="&"+input_objs[i].name+"="+input_objs[i].value
			}
			else{
				control_index++
			}
		}
		else if(input_objs[i].type=="select-one" && input_objs[i].selectedIndex!=0){
			control_len++
			if (input_objs[i].selectedIndex!=0){
				if (condition=="?")
					condition+=input_objs[i].name+"="+input_objs[i].value
				else
					condition+="&"+input_objs[i].name+"="+input_objs[i].value
			}
			else{
				control_index++
			}
		}
	}	
	if (control_index==control_len) {
		alert("请输入至少一项条件后进行导出操作")
		return false
	}
	else{
		this.href=this.href.replace(/\?.*/,"")
		this.href+=condition
	}
  });


$.datepicker.regional['zh-CN'] = {  
	closeText: '关闭',  
	prevText: '<上月',  
	nextText: '下月>',  
	currentText: '今天',  
	monthNames: ['一月','二月','三月','四月','五月','六月',  
	'七月','八月','九月','十月','十一月','十二月'],  
	monthNamesShort: ['一','二','三','四','五','六',  
	'七','八','九','十','十一','十二'],  
	dayNames: ['星期日','星期一','星期二','星期三','星期四','星期五','星期六'],  
	dayNamesShort: ['周日','周一','周二','周三','周四','周五','周六'],  
	dayNamesMin: ['日','一','二','三','四','五','六'],  
	weekHeader: '周',  
	dateFormat: 'yy-mm-dd',  
	firstDay: 1,  
	isRTL: false,  
	changeMonth: true,
	changeYear: true,
	showMonthAfterYear: true,  
	yearSuffix: '年'
};  

$.datepicker.setDefaults($.datepicker.regional['zh-CN']);

$( "#start_time" ).datepicker({
	defaultDate: '-30d'
});
$( "#end_time" ).datepicker({
	defaultDate: '-1d'
});

});
