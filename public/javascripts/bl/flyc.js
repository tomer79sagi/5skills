var admin_field_type_css_selector;
var admin_page_type;
var g_auth;
var g_server_url = "http://localhost:3002/";
var g_css_selectors_arr = {};
var g_flyc_id_counter = 0;
var g_selector_continuous = false;

var g_job_field_array = [['title', false, 0], ['description', false, 1]];
var g_job_field_array_iterator = 0;
var g_selector_modes_h = {'job_selector': 0, 'admin_selector': 1, 'facebook_selector': 2};
var g_selector_mode = -1;

// Testing
var g_facebook = true;
var g_facebook_access_token = null;
var g_selected_element = null;

var poll;
var timeout = 20; // 2 seconds timeout

function start() {
	window.jQuery = window.$ = jQuery;
	
	if (!$("body")) {
		poll();		
	} else {
		flyc_runthis();
	}
}

if (typeof jQuery == 'undefined') {
	var fJavascript = document.createElement('script');
	fJavascript.id = 'jQuery';
	fJavascript.type = 'text/javascript';
	fJavascript.src = g_server_url + 'javascripts/jquery-1.5.1.min.js';
	fJavascript.onload = start;
	document.body.appendChild(fJavascript);
} else {
	start();
}
	
function poll() {
//	console.log("polling... " + timeout);
	
	setTimeout(function(){
	timeout--;
	if ($("body")) {
		flyc_runthis();
	} else if (timeout > 0) {
//		console.log("re-poll called");
		poll();
	} else {
		// External library failed to load, try to load all scripts again
		alert("Failed to load");
	}}, 100);
}

function callbackFailure() {
//	alert('error');
}

function isScrolledIntoView(elem)
{
	if (!elem || !elem.offset()) { return; }
	
    var docViewTop = $(window).scrollTop();
    var docViewBottom = docViewTop + $(window).height();

    var elemTop = $(elem).offset().top;
    var elemBottom = elemTop + $(elem).height();

    return ((elemBottom >= docViewTop) && (elemTop <= docViewBottom)
      && (elemBottom <= docViewBottom) &&  (elemTop >= docViewTop) );
}

function loadFacebookSelector() {
	loadSelectorGadget(g_selector_modes_h["facebook_selector"], true);
//	addBorders($("#" + g_job_field_array[g_job_field_array_iterator][0]));
//	g_job_field_array[g_job_field_array_iterator][1] = true;
}

function facebookMouseDownEventHandler(element) {
	
	g_selected_element = element;

	// ***********
	// Start of an attempt to generalise the parsing of a 'style' element with a 'background-image' inside it
	// This will be useful for cases where the image is represented by a 'background-image' property in the 'style'
	// attribute
	// ***********
//	var elemStyle = $(element).attr("style");
//	var styleProperties = elemStyle ? elemStyle.split(";") : null;

	if (g_selected_element.tagName.toLowerCase() == "img") {
//		alert('xxx: ' + $(g_selected_element).attr("src"));
		
		var myImage = document.createElement("img");
	
		myImage.id = "post_image";
		myImage.src = $(g_selected_element).attr("src");
		myImage.setAttribute("style", "width:100px;height:auto;");
		
		$("#d_obj_preview").html("");
		$("#d_obj_preview").append(myImage);
	} else {
		$("#d_obj_preview").html("");
		$("#d_obj_preview").append('" ' + $(g_selected_element).text() + ' "');
	}
	
	
	// Populate the 'post' metadata
	var element_metadata = get_element_metadata();
	
	if (g_selected_element.tagName.toLowerCase() == 'img') {
		$("#d_flyc_name").html("Photo Flyced!");
		$("#d_flyc_caption").html(document.location.href);
		$("#d_flyc_description").html($(g_selected_element).attr("alt"));
	} else {
		$("#d_flyc_name").html("Text Flyced!");
		$("#d_flyc_caption").html(document.location.href);
		$("#d_flyc_description").html($(g_selected_element).text());
	}
	
	g_selector_continuous = false;
	
//	ajax_it('prepare_post');
}

function switchFlyc() {
	g_facebook = !g_facebook;
	
	flyc_runthis();
}

function loadJobSelector() {
	loadSelectorGadget(g_selector_modes_h["job_selector"], true);
	addBorders($("#" + g_job_field_array[g_job_field_array_iterator][0]));
	g_job_field_array[g_job_field_array_iterator][1] = true;
}

function jobSelectorMouseDownEventHandler(element) {
	
	// 1. Copy text to the selected field
	if (g_job_field_array[g_job_field_array_iterator][2] == 0) { // 0 = standard text field
		$("#" + g_job_field_array[g_job_field_array_iterator][0]).val($(element).html());
	} else if (g_job_field_array[g_job_field_array_iterator][2] == 1) { // 1 = Textarea
		$("#" + g_job_field_array[g_job_field_array_iterator][0]).html($(element).html());
	}
	
	if (g_job_field_array[g_job_field_array_iterator][1]) {
		removeBorders($("#" + g_job_field_array[g_job_field_array_iterator][0]));
		g_job_field_array[g_job_field_array_iterator][1] = false;
	}
	
	g_job_field_array_iterator++;
	
	if (g_job_field_array_iterator == g_job_field_array.length) {
		g_job_field_array_iterator = 0; 
		g_selector_continuous = false; 
	} else {
		if (!g_job_field_array[g_job_field_array_iterator][1]) {
			addBorders($("#" + g_job_field_array[g_job_field_array_iterator][0]));
			g_job_field_array[g_job_field_array_iterator][1] = true;
		}	
	}
}

function addBorders(elem) {
	$(elem).attr("style", $(elem).attr("style") + ";border-bottom:6px solid blue;");
};

function removeBorders(elem) {
	$(elem).attr("style", $(elem).attr("style") + ";border-bottom:1px solid gray;");
};

function loadSelectorGadget(selector_mode_i, selector_continuous_b) {
	try{
		g_selector_mode = selector_mode_i;
		g_selector_continuous = selector_continuous_b;
		
		if (typeof selector_gadget == 'undefined') {
			var fJavascript = document.createElement('script');
			fJavascript.id = 'selector_gadget';
			fJavascript.type = 'text/javascript';
			fJavascript.src = g_server_url + 'javascripts/bl/selectorgadget/selectorgadget.js';
			//	fJavascript.onload = function() {init_selector_gadget();};
			document.body.appendChild(fJavascript);
		} else {
			selector_gadget = new SelectorGadget();
			selector_gadget.makeInterface();
			selector_gadget.clearEverything();
			selector_gadget.setMode('interactive');
			selector_gadget.analytics();
		}
		
	} catch(e){ var ee = e.message || 0; alert('Error: \n\n'+e+'\n'+ee); }
}

// TODO:Merge functionality with 'createParsedTextAreaObject' and 'createParsedSelectObject' methods
function testParsing() {
	var currOption;
	var isSelected = false;
	var textToParse = $("#parse_text").val();
	
	if ($("#i_page_type").val() == "1") { // 1 = 'Search Results'
		var obj = $("#parse_select");
		
		// First, clear the select list
		$("#parse_select>option").each(function() {$(this).remove();});
		
		$(textToParse).each(function(i){
			
			$(this).attr("id", "flyc" + i);
			currOption = new Option($(this).text(), $(this).attr("id"));
			currOption.style.direction = "rtl";
			
			if (!isSelected && isScrolledIntoView($(this))) {
				currOption.selected = true;
				isSelected = true;
			}
			
			$(currOption).html($(this).text());
			obj.append(currOption);
		});
	
	} else {
		var field_obj = $(textToParse + ":first");
		
		$("#parse_select").val($(field_obj).text());
	}
	
	return false;
}

function doMagic(html_select_o){
	var element = $("[flyc_id='" + $(html_select_o).val() + "']");
	
	// Scroll to element
	$('html,body').animate({ scrollTop: $(element).offset().top }, { duration: 'slow', easing: 'swing'});
	 
	// If collapsable / expandable, perform a click (to open the div) on the selected element and close the previous one
	if ($('#chk_collapsable:checked').val()) { $(element).click(); }
}

function fb_callbackSuccess(data, textStatus, jqXHR) {
	alert('data: ');
}

function callbackSuccess(data, textStatus, jqXHR){
	if (!data) { alert('ERROR: No "data" object returned from server!'); return; }
	
	var status_i = parseInt(data.status);
	
	if (status_i < 100) { // 0 - 100 are system-type error messages
		alert('ERROR: ' + data.status + ', ' + data.action + ', ' + data.message);
		return;
	} else {
		// --- Redirects, system calls and processing functionality (only if successful)
		
		// 1. Clear all error fields (form fields) in case they had previous error messages
		$("#" + data.message_panel_name).html("");
		$("[id$=_error]").each(function() { $(this).html(""); });
		
		// 2. Display messages in message area
		if (data.message_panel_name && data.message_panel_message) {
			$("#" + data.message_panel_name).html(data.message_panel_message);
		}
		
		if (status_i >= 100 && status_i < 200) { // form OR data related errors
			
			// 2. Update the error messages for the appropriate form fields
			switch (status_i) {
				case 100: // Field validation error
					for (var key in data.errors) {	
						$("#" + key + "_error").html("'" + key + "' " + data.errors[key]);
					}
					
					break;
			}
			
			// 4. Update the 'logged-in' details panel
			if (data.logged_in_details_html) { $(this).html(data.logged_in_details_html); }
			
		} else { // No error
		
			// Call 'admin'-actions 'ajax-it' function
			if (data.action.match("^admin-")) {
				if (!data.is_admin) { alert("Admin flag should be set, but for some reason it's not! :-("); }
				
				eval("_aRES_" + data.action.substring(6) + "(data, status_i);");
			} else {
				eval("_RES_" + data.action + "(data, status_i);");	
			}
		}	
	}
}

// This function returns a 'Select' object populated with the parsed entities
function createParsedSelectObject(name_s, jquery_css_selector, size_i, width_s) {
	var currOption;
	var mySelect = document.createElement("select");
	var isSelected = false;
	
	if (!size_i) { size_i = 4; }
	if (!width_s) { width_s = "60%"; }
	
	mySelect.size = size_i;
	mySelect.id = name_s;
	mySelect.align = "left";
	mySelect.multiple = true;
	mySelect.setAttribute("onClick", "doMagic(this);");
	mySelect.setAttribute("style", "width:" + width_s + ";");
	
	if ($(jquery_css_selector)) {
		$(jquery_css_selector).each(function(i){
		
			if (!($(this).attr("flyc_id"))) {
				$(this).attr("flyc_id", g_flyc_id_counter++);
			}			

			currOption = new Option($(this).text(), $(this).attr("flyc_id"));
			currOption.style.direction = "rtl";
			
			if (!isSelected && isScrolledIntoView($(this))) {
				currOption.selected = true;
				isSelected = true;
			}
			
			mySelect.add(currOption);
			
		});
	}
	
	return mySelect;
}

function createParsedTextAreaObject(name_s, rows_i, field_type_i, jquery_css_selector) {
	var myTextArea = document.createElement("textarea");
	
	myTextArea.id = name_s;
	myTextArea.rows = rows_i;
	myTextArea.setAttribute("style", "width:60%;direction:rtl;");
	
	if (jquery_css_selector && $(jquery_css_selector)) {
		var field_obj = $(jquery_css_selector + ":first");
		
		if (field_obj) {
			myTextArea.innerHTML = $(field_obj).text();
			$(field_obj).attr("flyc_id", g_flyc_id_counter++);
			isScrolledIntoView($(field_obj));
		}
	}
	
	return myTextArea;
}

function checkBlankSelection(s_obj) {
	// Set the global parameter - 'page_id'
	$("#page_id").val($(s_obj).val());
	
	var option_text = $("#" + $(s_obj).attr("id") + ">option[value=" + $(s_obj).val() + "]").text();

	if ($(s_obj).val() == "-1" || option_text == "- Blank -") { // New 'Blank' selected
		$("#i_page_type_path").val("{blank}");
		$("#i_page_type_path").attr('disabled', 'true');
	} else {
		$("#i_page_type_path").removeAttr('disabled');
		
		if ($(s_obj).val() != "-2") {
			$("#i_page_type_path").val(option_text);
		} else {
			$("#i_page_type_path").val("");
		}
	}
}

// --------------- ADMIN ---------------
function changePageTypeWidget(s_page_type) {
	// Set the global parameter - 'i_page_type'
	$("#i_page_type").val($(s_page_type).val());
	$("#s_results_list").remove();
		
	// Update the 'css selector' - set to be DB
	$("#ta_field_css_selector").val(admin_field_type_css_selector);
	
	if ($(s_page_type).val() == "1") { // 1 = 'Search Results'
		// Change the parsed object to represent the page type definition
		$("#d_job_results").append(createParsedSelectObject("s_results_list", admin_field_type_css_selector));
		
		$("#parse_select").remove();
		$("#d_parse_results").append(createParsedSelectObject("parse_select", $("#parse_text").val()));
	} else { // All other types currently shouldn't be a list
		$("#d_job_results").append(createParsedTextAreaObject("s_results_list", 4, $(s_page_type).val(), admin_field_type_css_selector));
		
		$("#parse_select").remove();
		$("#d_parse_results").append(createParsedTextAreaObject("parse_select", 4, $(s_page_type).val(), $("#parse_text").val()));
	}
}

// --------------- ADMIN ---------------
function initPageAndFieldWidgets(css_selector_s, page_type_s) {
//	alert(css_selector_s + " ; " + page_type_s);

	admin_field_type_css_selector = css_selector_s;
	admin_page_type = page_type_s;
	$("#parse_text").html(admin_field_type_css_selector);
	
	// Populate the global 'css_selector' and 'page_type' attributes
	if (admin_field_type_css_selector) {
		testParsing();
	}
	
	if (admin_page_type) { changePageTypeWidget($("#i_page_type")); }
}

// TODO:Merge functionality with 'createParsedTextAreaObject' and 'createParsedSelectObject' methods
function updateExistingParsedObject(text_to_parse_s, object_to_populate_o, populate_type_i) {
	var currOption;
	var isSelected = false;
	
	if (populate_type_i == "1") { // 1 = 'Search Results'
		
		// First, clear the select list
//		$("#parse_select>option").each(function() {$(this).remove();});
		for (var option in object_to_populate_o.options) { $(option).remove(); }
			
		$(text_to_parse_s).each(function(i){
			$(this).attr("id", "flyc" + i);
			currOption = new Option($(this).text(), $(this).attr("id"));
			currOption.style.direction = "rtl";
			
			if (!isSelected && isScrolledIntoView($(this))) {
				currOption.selected = true;
				isSelected = true;
			}
			
			$(currOption).html($(this).text());
			$(object_to_populate_o).append(currOption);
		});
	
	} else {
		var field_obj = $(text_to_parse_s + ":first");
		
		$(object_to_populate_o).val($(field_obj).text());
	}
	
	return true;
}

// --------------- USER ---------------
function userInitFieldWidgets(parent_div_o, css_selector_s, page_type_s) {
	
	// Create the approprite parsed object (already parsed)
	var parsedObject = createParsedSelectObject("parse_select", css_selector_s, 6, "80%");
	
	// Append it to the HTML
	$(parent_div_o).append(parsedObject);
	
	// Parse the source HTML and populate the parsed object
//	updateExistingParsedObject(css_selector_s, $("#"), page_type_s);
}

function _aRES_get_site_and_page_panel(data, status_i) {
	$("#d_main_panel").html(data.panel_html);
	$("#d_widget_tabs").html(data.widget_tabs_html);
	
	// Update the 'page' details
	$("#page_id").val(data.page_id);
	$("#i_page_type").val(data.page_type);
}

function _aRES_get_fields_details_panel(data, status_i) {
	$("#d_main_panel").html(data.panel_html);
	$("#d_widget_tabs").html(data.widget_tabs_html);
	initPageAndFieldWidgets(data.jquery_css_selector, $("#i_page_type").val());
}

function _aRES_get_field_details(data, status_i) {
	$("#ta_field_css_selector").val(data.jquery_css_selector);
	
	initPageAndFieldWidgets(data.jquery_css_selector, $("#i_page_type").val());
}

function _aRES_save_field(data, status_i) {
	// Change the field_type id from default to DB generated (e.g. from -1 to 3345)
	$("#s_field_type>option[value=" + $("#s_field_type").val() + "]").val(data.field_id);
}

function _aRES_save_page(data, status_i) {
	// Change the 'blank' id to a real 'id' returned from the server request
	if (data.is_blank_uri_string) {
		$("#s_page_type_path>option[value=-1]").val(data.page_id);
	}
	else 
		if (data.is_new_uri_string) {
			// Add the newly added value to the list
			var o = new Option($("#i_page_type_path").val(), data.page_id);
			$(o).html($("#i_page_type_path").val());
			$("#s_page_type_path").append(o);
			
			// Select the option
			$("#s_page_type_path>option[value=" + data.page_id + "]").attr("selected", "true");
		}
	
	$("#organisation_id").val(data.organisation_id);
}

function _aRES_bookmark(data, status_i) {
	$('#logged_in_details').replaceWith(data.logged_in_details_html);
	$('#content_panel').prepend(data.content_html);
	$('#buttons_panel').replaceWith(data.buttons_html);
	$('#primary_messages').replaceWith(data.primary_messages_html);
	
	$('#logged_in_bar').show();
	
	$("#organisation_id").val(data.organisation_id);
	$("#url_path").val(data.url_path.slice(0, 15));
	
	ajax_it('admin-get_site_and_page_panel');
}

//
// This method is used to ping the server for 'session' information
// This method is used when the bookmarklet loads for the first time for a given page
// Once the call is used, the system will know if either the user is logged in -> and display the first screen
// OR if the user is required to login -> displaying the associated login screen
//
// 
// * server_action - name of the action to be called. This name will look for the rails 'bl_{server_action}'
//   				 action and also for the '{server_action}' message in the 'simple.html.erb' file (the
//					 session-based client-server gateway
// * success_action - name of the 'ajax_it' action to invoke on the client in case the call was SUCCESSFUL
// * fail_action - name of the 'ajax_it' action to invoke on the client in case the call FAILED
//
function callServer(server_action, request_data, client_data, success_action, fail_action) {
	
	var server_url = g_server_url + "bookmarklet/" + server_action;
	var client_request = server_action;
	
	// The following code is required to send information to the server
	if (request_data) {
		server_url += "?";
		var i = 0;
		
		for (key in request_data) {
			if (i++ >0) { server_url += "&"; }
			server_url += key + "=" + request_data[key];
		}	
	} else {
//		alert('empty request_data');
	}
	
	// Configure the client request params
	if (client_data) {
		client_request += "?";
		var i = 0;
		
		for (key in client_data) {
			if (i++ >0) { client_request += "&"; }
			client_request += key + "=" + client_data[key];
		}	
	} else {
//		alert('empty request_data');
	}

//	alert('client_request: ' + client_request + "\n\r\n\r" + server_url);

	if (g_facebook) {
	
		var socket = new easyXDM.Socket({	
	
		remote: server_url,
		
		container: document.getElementById("external_panel"),
				
		// SERVER -> CLIENT MESSAGE
		onMessage: function(message, origin){
			if (!message) { return; }

			var message_content = message.split(":");
			
//			alert("[BOOKMARKLET] Received user key '" + message + "' from '" + origin + "'");

			if (message_content[0] == 'facebook-token') {
				ajax_it('socially_logged_in');
				var message_body = message_content[1].split(",");
				
//				alert("https://graph.facebook.com/" + message_body[0] + "/movies" + "?access_token=" + message_body[1]);

				g_facebook_access_token = message_body[1]; 
				
				$("#external_panel").html("");	
				$("#external_panel").append("<image src='https://graph.facebook.com/" + message_body[0] + "/picture?type=small'/>");
				
				// the 'access token'
//				message_body[1]
				
			// User NOT LOGGED IN at host site
			// --------------------------------------
			} else if (message_content[0] == 'err' && message_content[1] == '000') {
				ajax_it(fail_action);
			// --------------------------------------
			
			// User LOGGED IN at host site
			// --------------------------------------
			} else if (message_content[0] == 'key') {
				// Set the authenticity token for 'cookie'-like login for the bookmarklet
				g_auth = message_content[1];
				
				// Set teh 'ajax-setup' function to include a header of the retrieved key
				$.ajaxSetup({
				  beforeSend: function(xhr) {
				    xhr.setRequestHeader('bookmarklet_session_token', g_auth);
				  }
				});
				
				ajax_it(success_action);
				
			//User LOGGED OUT at the host site
			} else if (message_content[0] == 'code' && message_content[1] == '200') {
				ajax_it(success_action);
			}
			// --------------------------------------
		},
		
		// Once the CLIENT -> SERVER link is setup, make the call to the server.
		// This method is required to obtain a resposne from the server
		// This method will call the server-side method which in turn will invoke the 'onMessage()'
		// method above.
		onReady: function(){
//			alert('ABOUT TO POST: client_request: ' + client_request);
			document.getElementById("external_panel").children[0].height = "40px";
			document.getElementById("external_panel").children[0].style.padding = "0em 0em 0em 0em;";
			document.getElementById("external_panel").children[0].scrolling = "no";
			socket.postMessage(client_request);
		}
	});
		
	} else {
		
		var socket = new easyXDM.Socket({	
	
		remote: server_url,
				
		// SERVER -> CLIENT MESSAGE
		onMessage: function(message, origin){
			if (!message) { return; }

			var message_content = message.split(":");
			
//			alert("[BOOKMARKLET] Received user key '" + message + "' from '" + origin + "'");
				
			// User NOT LOGGED IN at host site
			// --------------------------------------
			if (message_content[0] == 'err' && message_content[1] == '000') {
				ajax_it(fail_action);
			// --------------------------------------
			
			// User LOGGED IN at host site
			// --------------------------------------
			} else if (message_content[0] == 'key') {
				// Set the authenticity token for 'cookie'-like login for the bookmarklet
				g_auth = message_content[1];
				
				// Set teh 'ajax-setup' function to include a header of the retrieved key
				$.ajaxSetup({
				  beforeSend: function(xhr) {
				    xhr.setRequestHeader('bookmarklet_session_token', g_auth);
				  }
				});
				
				ajax_it(success_action);
				
			//User LOGGED OUT at the host site
			} else if (message_content[0] == 'code' && message_content[1] == '200') {
				ajax_it(success_action);
			}
			// --------------------------------------
		},
		
		// Once the CLIENT -> SERVER link is setup, make the call to the server.
		// This method is required to obtain a resposne from the server
		// This method will call the server-side method which in turn will invoke the 'onMessage()'
		// method above.
		onReady: function(){
			socket.postMessage(client_request);
		}
	});
		
	}
}

function _aREQ_get_site_and_page_panel() {
	var json_arr = {};
		
	json_arr.site_page_id = $("#page_id").val();
	json_arr.site_organisation_id = $("#organisation_id").val();
	json_arr.url_path = $("#url_path").val();
	
	$.post(g_server_url + "bookmarklet/admin/panel/site_and_page_details", {
		json: JSON.stringify(json_arr)}, callbackSuccess, "json");
}

function _aREQ_get_fields_details_panel() {
	var json_arr = {};
		
	if ($("#s_page_type_path").val() == "" || parseInt($("#s_page_type_path").val()) <= 0) {
		alert("You must save a 'Page' before you can create / edit its fields !");
	} else {
	
		json_arr.site_page_id = $("#page_id").val();
		
		$.post(g_server_url + "bookmarklet/admin/panel/fields_details", {
			json: JSON.stringify(json_arr)}, callbackSuccess, "json");
		
	}
}

function _aREQ_get_field_details() {
	var json_arr = {};
		
	json_arr.field_type = $("#s_field_type").val();
	
	$.post(g_server_url + "bookmarklet/admin/field/details", 
		{ json: JSON.stringify(json_arr) }, callbackSuccess, "json");
}

function _aREQ_save_page() {
	var json_arr = {};
		
	json_arr.site_organisation_id = $("#organisation_id").val();
	json_arr.site_organisation_type_id = $("#s_organisation_type").val();
	json_arr.site_url = $("#site_url").text();
	json_arr.site_name = $("#organisation_name").val();
	json_arr.page_type_path_selection = $("#s_page_type_path").val(); // The 'page_id'
	json_arr.page_type_path = $("#i_page_type_path").val();
	json_arr.page_type = $("#page_type").val();
	
	$.post(g_server_url + "bookmarklet/admin/save_page", 
		{ json: JSON.stringify(json_arr) }, callbackSuccess, "json");
}

function _aREQ_save_field() {
	var json_arr = {};
		
	json_arr.field_type = $("#s_field_type").val();
	json_arr.jquery_css_selector = $("#ta_field_css_selector").val();
	json_arr.site_page_id = $("#page_id").val();
	
	$.post(g_server_url + "bookmarklet/admin/field/save", 
		{ json: JSON.stringify(json_arr) }, callbackSuccess, "json");
}

function _RES_save_job(data, status_i) {
	alert('single job saved!');
	
	$("#role_id").val(data.role_id);
}

function _RES_save_jobs(data, status_i) {
	alert('jobs saved!');
		
	for (role_id in data.role_ids) {
		// 1. Change the 'select' object values
		$("#parse_select>option[value='-1:" + role_id + "']").val('-1:' + data.role_ids[role_id]);
		
		// 2. Change the 'parsed html' object 'flyc_id's
		for (var a in g_css_selectors_arr) {
//			alert(a + ":" + role_id + " | \n\r" + $("[flyc_id='" + a + ":" + role_id + "']").html());
			$("[flyc_id='" + a + ":" + role_id + "']").attr("flyc_id", a + ":" + data.role_ids[role_id]);
//			alert(a + ":" + data.role_ids[role_id] + " | \n\r" + $("[flyc_id='" + a + ":" + data.role_ids[role_id] + "']").html());
		}
	}
}

function _RES_get_new_role_panel(data, status_i){
	$("#d_main_panel").html(data.panel_html);
	$("#d_widget_tabs").html(data.widget_tabs_html);
	$('#buttons_panel').replaceWith(data.buttons_html);
	
	if (data.role) {
		$("#role_id").val(data.role['id]']);
		$("#title").val(data.role['title']);
		$("#description").html(data.role['description']);
	} else {
		$("#role_id").val(data.role_id);
	}
}

function _RES_get_actions_panel(data, status_i){
	$("#d_main_panel").html(data.panel_html);
	$("#d_widget_tabs").html(data.widget_tabs_html);
}

function _RES_get_unknown_panel(data, status_i){
	$("#d_main_panel").html(data.panel_html);
	$("#d_widget_tabs").html(data.widget_tabs_html);
	$("#role_id").val(data.role_id);
	
	ajax_it("get_new_role_panel");
}

function _RES_get_apply_panel(data, status_i){
	$("#d_main_panel").html(data.panel_html);
	$("#d_widget_tabs").html(data.widget_tabs_html);
//	$('#buttons_panel').replaceWith(data.buttons_html);
}

function _RES_get_job_panel(data, status_i) {
	$("#d_main_panel").html(data.panel_html);
	$("#d_widget_tabs").html(data.widget_tabs_html);
	$('#buttons_panel').replaceWith(data.buttons_html);
	
	if (data.role) {		
		$("#role_id").val(data.role['id]']);
		$("#title").val(data.role['title']);
		$("#description").html(data.role['description']);
	} else {
		$("#role_id").val(data.role_id);
		$("#title").val($("[flyc_id='-1:-1']").html());
		$("#description").html($("[flyc_id='-2:-1']").html());
	}
}

function _RES_get_search_results_panel(data, status_i) {
	// This call will display or identify jobs that were already saved to Flyc
	$("#d_main_panel").html(data.panel_html);
	$("#d_widget_tabs").html(data.widget_tabs_html);
	
	// This block of code should be returned potentially from the server (as HTML)
	userInitFieldWidgets(
		$('#d_job_selection'), 
		g_css_selectors_arr["-1"], 
		data.page_type);
}

function _RES_login(data, status_i) {
	$('#content_panel').replaceWith(data.content_html);
	$('#buttons_panel').replaceWith(data.buttons_html);
	$('#primary_messages').replaceWith(data.primary_messages_html);
}

function _RES_process_login(data, status_i) {
	// Notify the server (for correct session usage) of the login
	callServer("notify_login", 
		{key: data.key, remember_me_flag: data.remember_me_flag},
		null , 
		'bookmark_site', 'login');
}

function _RES_logout(data, status_i) {
	callServer("notify_logout", 
		{ key: data.key },
		null ,  
		'login', 'login');
}

function _RES_bookmark(data, status_i) {
	var curr_field_o;
	var j;

	$('#logged_in_details').replaceWith(data.logged_in_details_html);
	$('#content_panel').replaceWith(data.content_html);
	$('#buttons_panel').replaceWith(data.buttons_html);
	$('#primary_messages').replaceWith(data.primary_messages_html);
	
	$('#logged_in_bar').show();
	
	// Update the 'page' details
	$("#page_id").val(data.page_id);
	$("#i_page_type").val(data.page_type);
	$("#organisation_id").val(data.organisation_id);
	$("#role_application_id").val(data.role_application_id);
	$("#url_path").val(data.url_path);
	
	// Create all necessary 'flyc' tags in the source HTML
	// ---------------------- TAG FLYC ELEMENTS ----------------------
	for (field in data.jquery_css_selectors_arr) {
		curr_field_o = data.jquery_css_selectors_arr[field]['website_parsing_field'];
		g_css_selectors_arr[curr_field_o['field_type']] = curr_field_o['jquery_css_selector'];
		j = -1;
		
		// Tag all elements
		// ***** ASSUMPTION: Each selector-type element has the same size of array and elements
		// 				     with same index are related
		//
		// Iterate through all 'selected' elements and tag them with a 'flyc' attribute
		$(g_css_selectors_arr[curr_field_o['field_type']]).each(function() {
//			alert(curr_field_o['field_type'] + ":" + i + ": " + $(this).html());
			$(this).attr("flyc_id", curr_field_o['field_type'] + ":" + j--);
		});
	}
	
//	alert('flyc_id: ' + $("[flyc_id='-1:0']").html());
	// ---------------------- TAG FLYC ELEMENTS ----------------------
	
	// If 'page_type' = 'Search results', display a 'select' HTML object and parse the HTML page
	changePanelBasedOnPagetype(data.page_type);
}

function changePanelBasedOnPagetype(page_type_i) {
	switch (page_type_i) {
		
		case 0: // 'unknown'
			ajax_it("get_unknown_panel");
			break;
			
		case 1: // 'search results'
			ajax_it("get_search_results_panel");
			break;
			
		case 2: // Job page
			ajax_it("get_job_panel");
			break;			
						
		case 3: // Apply page
			ajax_it("get_apply_panel");
			break;	
	}
}

function _REQ_process_login() {
	var json_arr = {};
			
	json_arr.person_login = {};
	json_arr.person_login.email = $("#email").val();
	json_arr.person_login.password = $("#password").val();

	json_arr.save_login = {};
	json_arr.save_login.checked = $("#remember_me").attr("checked") == true ? "yes" : "no";
	
	$.post(g_server_url + "bookmarklet/process_login", 
		{ json: JSON.stringify(json_arr) }, callbackSuccess, "json");
}

function _REQ_login() {
	$.get(g_server_url + "bookmarklet/login", 
		{  }, callbackSuccess, "json");
}

function _RES_prepare_post(data, status_i) {
	alert('blah');
}

function _REQ_prepare_post() {
	var json_arr = {};

	json_arr.html = $(g_selected_element).html();
	
	$.post(g_server_url + "bookmarklet/social/post/prepare", 
		{ json: JSON.stringify(json_arr) }, callbackSuccess, "json");
}

function _RES_social_post(data, status_i) {
	if (data.id) {
		alert('Successfully posted the entry!');
	} else if (data.error) {
		alert('ERROR: ' + data.error.message);
	}
}

function get_element_metadata() {
	var element_metadta = {};
	
	if (g_selected_element.tagName.toLowerCase() == 'img') {
		element_metadta.picture = $(g_selected_element).attr("src");
		element_metadta.description = $(g_selected_element).attr("alt");
	} else {
		element_metadta.picture = "";
		element_metadta.description = $(g_selected_element).text();
	}
	
	element_metadta.message = $("#comment_text").val();
	element_metadta.link = null;
	element_metadta.name = "Photo Flyced!";
	element_metadta.caption = document.location.href;
	
	return element_metadta;
}

function _REQ_facebook_post() {
		
	var json_arr = {};
	
	json_arr.url = document.location.href;
	json_arr.post = get_element_metadata();
	
	json_arr.social = {};
	json_arr.social.provider = "facebook";
	json_arr.social.access_token = g_facebook_access_token;
	
	$.post(g_server_url + "bookmarklet/social/post", 
		{ json: JSON.stringify(json_arr) }, callbackSuccess, "json");
}

function _REQ_social_login() {
	callServer("social_login", null, null , 'bookmark_site', 'login');
}

function _REQ_socially_logged_in() {
	 
}

function _REQ_logout() {
	$.post(g_server_url + "bookmarklet/logout", 
		{ json: null }, callbackSuccess, "json");
}

function _REQ_ping() {
	// ATTEMPT - part of the re-use and automation for dynamically loading scripts
	// -----------------------------
//	if (jsLoaded['easyXDM'].loaded_flag) {
//		callServer();
//	} else {
//		alert('not ready');
//	}
	// -----------------------------
	if (typeof easyXDM == 'undefined') {
		var fJavascript = document.createElement('script');
		fJavascript.id = 'easyXDM';
		fJavascript.type = 'text/javascript';
		fJavascript.src = g_server_url + 'javascripts/bl/easyXDM/easyXDM.min.js';
		fJavascript.onload = function() {callServer("check_session", null, null , 'bookmark_site', 'login');};
		document.body.appendChild(fJavascript);
	} else {
		callServer("check_session", null, null , 'bookmark_site', 'login');
	}
}

function _REQ_get_search_results_panel() {
	// Here, the system will collect all currently displayed roles
	// Perform a text search on the server (based on title and description) to identify already saved jobs
	// In case jobs were found, the system will 'disable' them from being selected in the list
	
	var json_arr = {};

	json_arr.site_page_id = $("#page_id").val();
	json_arr.site_organisation_id = $("#organisation_id").val();
	json_arr.url_path = $("#url_path").val();
	
	$.post(g_server_url + "bookmarklet/panel/search_results", {
		json: JSON.stringify(json_arr)}, callbackSuccess, "json");
}

function _REQ_get_unknown_panel() {
	// Here, the system will collect all currently displayed roles
	// Perform a text search on the server (based on title and description) to identify already saved jobs
	// In case jobs were found, the system will 'disable' them from being selected in the list
	var json_arr = {};
	json_arr.page_type = $("#i_page_type").val();
	
	$.post(g_server_url + "bookmarklet/panel/unknown", {
		json: JSON.stringify(json_arr)}, callbackSuccess, "json");
}

function _REQ_get_actions_panel() {
	var json_arr = {};
	json_arr.page_type = $("#i_page_type").val();
	
	$.post(g_server_url + "bookmarklet/panel/actions", {
		json: JSON.stringify(json_arr)}, callbackSuccess, "json");
}

function _REQ_get_apply_panel() {
	var json_arr = {};
	json_arr.page_type = $("#i_page_type").val();
	
	$.post(g_server_url + "bookmarklet/panel/apply", {
		json: JSON.stringify(json_arr)}, callbackSuccess, "json");
}

function _REQ_get_new_role_panel() {
	var json_arr = {};
	json_arr.page_type = $("#i_page_type").val();
	json_arr.role_id = $("#role_id").val();
	
	$.post(g_server_url + "bookmarklet/panel/new_role", {
		json: JSON.stringify(json_arr)}, callbackSuccess, "json");
}

function _REQ_get_facebook_panel() {
	$.post(g_server_url + "bookmarklet/panel/facebook", {}, callbackSuccess, "json");
}

function _RES_get_facebook_panel(data, status_i) {
	$("#content_panel").html(data.panel_html);
	$('#buttons_panel').replaceWith(data.buttons_html);
}

//
// Assumption, this method is called once a page has been identified as a 'job' page
// That's why the bookmarklet will attempt and parse the HTML page assuming it's a 'job' page
//
function _REQ_get_job_panel() {
	// Here, the system will collect all currently displayed roles
	// Perform a text search on the server (based on title and description) to identify already saved jobs
	// In case jobs were found, the system will 'disable' them from being selected in the list
	var json_arr = {};
	json_arr.page_type = $("#i_page_type").val();
	json_arr.role_id = $("#role_id").val();	
	json_arr.jobs = {};
	json_arr.jobs.job1 = {};
		
	for (var a in g_css_selectors_arr) {
//		alert('vv: ' + g_css_selectors_arr);
		json_arr.jobs["job1"][a] = $("[flyc_id='" + a + ":" + 0 + "']").html();
	}
	
	$.post(g_server_url + "bookmarklet/panel/job", {
		json: JSON.stringify(json_arr)}, callbackSuccess, "json");
}

function _REQ_save_job_and_close(){
	_REQ_save_job();
	
	alert("'Close' functionality not implemented yet!");
}

// 
// !!!!! This function has a duplicated implementation of '_REQ_get_job_panel'
// -- Consider merging
//
function _REQ_save_job(){
	var json_arr = {};
	json_arr.jobs = {};
	json_arr.jobs.job1 = {};
	json_arr.jobs.job1.role_id = $("#role_id").val();
	
	json_arr.jobs["job1"]["-1"] = $("#title").val();
	json_arr.jobs["job1"]["-2"] = $("#description").html();
	
	$.post(g_server_url + "bookmarklet/job/save", {
		json: JSON.stringify(json_arr)}, callbackSuccess, "json");
}

function _REQ_save_jobs_and_close(){
	_REQ_save_jobs();
	
	alert("'Close' functionality not implemented yet!");
}

function _REQ_save_jobs() {
	var json_arr = {};
			
	// determine if this page contains a list of jobs or just 1 job
	if ($("#i_page_type").val() == "1") { // 'Search results' - a list
		var jobs_arr = $("#parse_select").val();
		var j = 1;
		json_arr.jobs = {};

//		alert(jobs_arr);
		
		for (var job in jobs_arr) {
			json_arr.jobs["job" + j] = {};
			json_arr.jobs["job" + j].role_id = jobs_arr[job].split(":")[1];
			
			for (var a in g_css_selectors_arr) {
//				alert(a + ":" + jobs_arr[job].split(":")[1]);
				json_arr.jobs["job" + j][a] = $("[flyc_id='" + a + ":" + jobs_arr[job].split(":")[1] + "']").html();
				
//				alert('field: ' + a + ":" + jobs_arr[job] + " ; " + 
//					json_arr.jobs["Job" + j].field_type + "\n\r" + 
//					json_arr.jobs["Job" + j].content);
			}
			
			j++;
		}
		
	} else {
		
		// Grab the form fields from the bookmarklet (don't grab the parsed text at this point)
		
//		var json_arr = {};
//		json_arr.jobs = {};
//		json_arr.jobs.job1 = {};
//			
//		for (var a in g_css_selectors_arr) {
//			json_arr.jobs["job1"][a] = $("[flyc_id='" + a + ":" + 0 + "']").html();
//		}
	}
//			
	$.post(g_server_url + "bookmarklet/jobs/save", 
		{ json: JSON.stringify(json_arr) }, callbackSuccess, "json");
}

function _REQ_bookmark_site() {
	
	// Facebook - temporary change
	if (g_facebook) {
		ajax_it("get_facebook_panel");
		loadFacebookSelector();
				
		return;
	}	
	
	$.post(g_server_url + "bookmarklet/bookmark_site", 
		{ url:document.location.href }, callbackSuccess, "json");
}

function ajax_it(action, target_field_o) {
	
	var is_no_post_action = false;
	var url_action = "";
	var request_attributes;

	try{
		
		if (g_auth) {
			$.ajaxSetup({
				  beforeSend: function(xhr) {
				    xhr.setRequestHeader('bookmarklet_session_token', g_auth);
				  }
				});
		} else if (action != 'ping') {
//			alert("'g_auth' key is not set!");
		}
		
		// Call 'admin'-actions 'ajax-it' function
		if (action.match("^admin-")) { eval("_aREQ_" + action.substring(6) + "();"); return; }
				
		if (action == 'ping' ||
			action == 'bookmark_site' ||
			
			action == 'login' ||
			action == 'social_login' ||
			action == 'process_login' ||
			action == 'logout' ||
			
			action == 'get_job_panel' || 
			action == 'get_new_role_panel' ||
			action == 'get_apply_panel' ||
			action == 'get_actions_panel' ||
			action == 'get_unknown_panel' ||
			action == 'get_search_results_panel' ||
			
			action == 'get_facebook_panel' ||
			action == 'facebook_post' ||
			action == 'prepare_post' ||  
			
			action == 'save_job' ||
			action == 'save_job_and_close' ||
			action == 'save_jobs' ||
			action == 'save_jobs_and_close') {
			
				eval("_REQ_" + action + "();");	
				is_no_post_action = true;
		
		} else if (action == 'move_widget') {
		
			slide_it($("#flyc_panel"), true);
			is_no_post_action = true;
		
		// Display actions	
		} else if (action == 'actions') {
			
			url_action = g_server_url + "bookmarklet/actions";
		
		// Display Job ad form	
		} else if (action == 'job_ad') {
			
			url_action = g_server_url + "bookmarklet/job_ad";
		
		// The mapping of the actions to Flyc application actions	
		} else if (action == 'grab_job_fields') {
			
			$("#title").attr("value", $("h1[class='jobtitle']").text());
			$("#salary_max").attr("value", $('div[class="content"]>h1>span').text());
			$("#role_location").attr("value", $("dl[class='classifiers']>dd").text());
//			$("div[@class='templatetext").val();
					
			is_no_post_action = true;
		
		// The mapping of the actions to Flyc application actions	
		} else if (action == 'populate_apply_fields') {
			
//			$.clipboardReady(function(){
//				$( "a" ).click(function(){
//					$.clipboard( "You clicked on a link and copied this text!" );
//					return false;
//				});
//			});

			ZeroClipboard.setMoviePath( g_server_url + 'javascripts/bl/zeroclipboard/ZeroClipboard.swf' );
			var clip = new ZeroClipboard.Client();
			
			clip.addEventListener( 'onComplete', my_click );
			
			clip.setText( g_server_url + "uploads/Letter.txt" );
			clip.glue( 'd_clip_button', 'd_clip_container' );
//			var html=clip.getHTML(100, 30);
			
//			$("embed").each(function(){
////				alert($(this).attr('name'));
//				
//				$(this).click();
//			});
						
			$("#FirstName").attr("value", "Tomer");
			$("#LastName").attr("value", "Sagi");
			$("#PhoneNumber").attr("value", "00972526066556");
			$("#CoverLetterTypeWrite").attr("checked","checked");
//			alert($("input[name=ResumeUpload]").attr("value", "SSS"));
			$("input[name=ResumeUpload]").click(function() {alert('tomer');});
//			$("input[name=ResumeUpload]").trigger('click');

			$("d_clip_button").click();

			is_no_post_action = true;
		
		// The mapping of the actions to Flyc application actions	
		} else if (action == 'parse_page') {
			
			url_action = g_server_url + "bookmarklet/parse_page";
			request_attributes = {};
		
		// The mapping of the actions to Flyc application actions	
		} else if (action == 'copy_selection') {
			
			target_field_o.attr('value', $.trim(getSelText().toString()));
			is_no_post_action = true;
		
		// The mapping of the actions to Flyc application actions	
		} else if (action == 'save' || action == 'save_and_close' || 
				action == 'update' || action == 'update_and_close') {
			
			$("#btn_save").attr('disabled', 'disabled');
			$("#btn_save_and_close").attr('disabled', 'disabled');
			$("#btn_close").attr('disabled', 'disabled');
			
			url_action = g_server_url + "bookmarklet/process_bookmark_site";
			
		} else if (action == 'flyc_role') {
			
			window.open(g_server_url + "application/" + $("#role_application_id").val() + "/view", 'flyc_window');
			is_no_post_action = true;
			
		} else if (action == 'extend') {
			
			$("#flyc_panel").animate({
				width: '400px',
				height: '300px'
			});
			is_no_post_action = true;
			
		} else if (action == 'close') {
			
			slide_it($("#flyc_panel"));
			is_no_post_action = true;
			//setTimeout("$('#flyc_panel').remove()", 500);
		
		}
		
		// If there is no need for a post, clear the 'throbber' and remain on screen
		if (is_no_post_action) {
//		  	$.throbberHide({parent: $("#processing_indicator")});
			return;
			
		// If there is a post required, grab the current action and prepare the relevant post parameters
		// before sending them across
		} else if ($("#current_action").length) {
			
//			alert ($("#current_action").val());
			
			// Check current action to establish the fields that are required to be transmitted
			if ($("#current_action").val() == 'bl_bookmark_site' || $("#current_action").val() == 'bl_job_ad') {
				
				request_attributes = {
					'role[title]': encodeURIComponent($("#title").val()),
					'role[salary_max]': $("#salary_max").val(),
					'role_location': $("#role_location").val(),
					'submit_action': action,
					'application_id': $("#role_application_id").val(),
					'role_application[status_id]': $("#status").val()
				};
				
			// 'bl_login' action covers for the first time the user is trying to login.
			// 'bl_process_login' caters for the 2nd onwards times the user is trying to login
			} else if ($("#current_action").val() == 'bl_login' || $("#current_action").val() == 'bl_process_login') {
				
				request_attributes = {
					'person_login[email]': $("#email").val(),
					'person_login[password]': $("#password").val(),
					'save_login[checked]': $("#remember_me").val(),
					'return_to': $("#return_to").val()
				};
				
			} else {
				
				request_attributes = {};
				
			}
		}
		
		// Based on jQuery documentation, JSOP-type requests (which I think is what I'm using)
		// don't return a standard 'jqxhr' object, they return an 'undefined' response (tested)
		//alert(request_attributes["url"]);
		var params_s = "";
		var t_param = "";
		
		if (request_attributes && request_attributes.length && $('#flyc_token').val() != '') {
			request_attributes[request_attributes.length] = '&flyc_token=' + $('#flyc_token').val();
		}
		
		for (var p in request_attributes) {
			t_param = p + '=' + request_attributes[p];
			
			if (params_s != "") { params_s += "&"; }
			params_s += t_param;
		}
		
	  	send_ajax(url_action, params_s);

//		try_again();
	   
   } catch(e){ var ee = e.message || 0; alert('Error: \n\n'+e+'\n'+ee); }
}

// ---------------------
// This method was initially developed to support a 'try again' with the 'split' implementation
// As at the 29th of Feb, 2012, this implementation is no longer relevant, so ignoring it at the moment
// ---------------------
//function try_again() {
//  setTimeout(function() {
//    if (retries_counter++ < 3 && $('#reply_received_flag').val() == 'waiting') {
//      alert('trying: ' + retries_counter + ' of ' + retries_count_max);
//      try_again();
//    } else {
//	  retries_counter = 0;
//	}
//  }, 10000);
//}

function send_ajax(url_action, params_s) {
//	alert('url_action: ' + url_action);
//	alert('params: ' + params_s);
	
	var jqxhr = $.ajax({
			url: url_action,
			type: "GET",
			data: params_s,
			processData: false,
			crossDomain: true,
			dataType: "script"
		});
}

function flyc_runthis() {
		
	try{
	
    if (!$("#flyc_panel") || $("#flyc_panel").length == 0) {
        s = document.location;
		
        if ((s != "") && (s != null)) {
            $("body").append("\
				<div id='flyc_panel' style='direction:ltr;'>\
					\
					<div id='inner_panel' style='padding:.35em .35em .35em .35em;direction:ltr;'>\
						\
						<input type=\"hidden\" id='flyc_token'>\
						\
						<div id='flyc_header' style='direction:ltr;'>\
							<table>\
								<tr>\
									<td><span style='font-size: 20pt; padding: .25em 0em .5em 0em;'>Flyc - Bookmark</span></td>\
									<td id='processing_indicator' style='padding:0em 0em 0em 1.5em;'>\
										<button onClick='switchFlyc(); return false;'>Switch</button>\
									</td>\
								</tr>\
							</table>\
							<table id='logged_in_bar' style='display:none;width:100%;'>\
								<tr>\
									<td id='logged_in_details' style='text-align:left;width:50%;'></td>\
									<td id='feedback' style='padding:0em 0em 0em 1.5em;text-align:right;width:50%;'>Feedback</td>\
								</tr>\
							</table>\
							\
							<hr/>\
							\
						<div id='external_panel'></div>\
						\
						</div>\
						\
						<div id='primary_messages' style='padding:0em 0em 0em 0em;'></div>\
						\
						<form style='padding:0em 0em 0em 0em;'>\
							<div id='content_panel'></div>\
						</form>\
					</div>\
				</div>\
				\
                <style type='text/css'>\
                    #flyc_panel { position: fixed; text-align:left; top: 0%; left: 60%; width: 350px; height: 99%; z-index: 999; border: 5px solid rgba(0,0,0,.5); background-color:#ffffff;color:#000000;}\
					#field_error { color:#000000; font-size:8pt; }\
					#field_success { color:#000fff; font-size:8pt; }\
					#messages_panel { float:left;display: none; width:100px;background-color:#333333;color:#ffffff; font-size:9pt; }\
                </style>");
			
			$("#flyc_panel").height(window.innerHeight - 10);
			
			// Slide down the flyc panel
			slide_it($("#flyc_panel"));
			
//			$.throbberShow({parent: $("#processing_indicator"), image: g_server_url + "images/ajax-loader.gif"});
			//$("#btn_save").throbber("click", {image: g_server_url + "images/ajax-loader.gif"});
			
			// Parse the site			
			ajax_it('ping');
        }
    } else {
//        slide_it($("#flyc_panel"));
	
		// Temporary for debugging purposes, refresh the 'flyc' widget
		$("#flyc_panel").remove();
		
		flyc_runthis();
    }
	
	} catch(e){ var ee = e.message || 0; alert('Error: \n\n'+e+'\n'+ee); }
    
}

function slide_it(panel_o, is_toggle) {
	var is_hide_embed_elements = false;
	
	if (!is_toggle) {
		is_toggle = false;
	}
		
	var avail_screen_width_i = window.top.document.documentElement.clientWidth;
	var panel_left_i = parseInt(panel_o.css('left'), 10);

	if (panel_left_i != 0 && panel_left_i != -360 && 
			panel_left_i != avail_screen_width_i && panel_left_i != (avail_screen_width_i - 360)) {
		$("#flyc_panel").css("left", avail_screen_width_i);
	}
	
	// Open panel from right OR slide panel from left to right
	if ((panel_left_i == avail_screen_width_i) || 
			(is_toggle && panel_left_i == 0)) { // Closed and at right OR open, at left and toggle
		is_hide_embed_elements = true;
		left_end_point_i = avail_screen_width_i - panel_o.outerWidth();
		
	// Open panel from left OR slide panel from right to left
	} else if ((panel_left_i == -panel_o.outerWidth()) || 
			(is_toggle && panel_left_i == (avail_screen_width_i - panel_o.outerWidth()))) { // Closed and at left OR open, at right and toggle
		is_hide_embed_elements = true;
		left_end_point_i = 0;
		
	// Close panel - panel at left side
	} else if (panel_left_i == 0) { // Open and at left
		left_end_point_i = -panel_o.outerWidth();
		
	// Close panel - panel at right side
	} else if (panel_left_i == (avail_screen_width_i - panel_o.outerWidth())) { // Open and at right
		left_end_point_i = avail_screen_width_i;
		
	// Default = Open panel from the right
	} else { // Default
		is_hide_embed_elements = true;
		left_end_point_i = avail_screen_width_i - panel_o.outerWidth();
	}
	
	// Check closed and open status for showing and hiding flash elements
	if (is_hide_embed_elements) {
		$("embed").each(function(){ $(this).hide(); });
	} else {
		$("embed").each(function(){ $(this).show(); });
	}
	
	panel_o.animate({left: left_end_point_i});
}
 
function getSelText() {
    var s = '';
    if (window.getSelection) {
        s = window.getSelection();
    } else if (document.getSelection) {
        s = document.getSelection();
    } else if (document.selection) {
        s = document.selection.createRange().text;
    }
    return s;
}
