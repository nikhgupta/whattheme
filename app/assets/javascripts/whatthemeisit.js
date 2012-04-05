(function(){

  // the minimum version of jQuery we want
  var v = "1.3.2";

  // include some javascripts in our bookmarklet
  function loadScript(url) {
    var script = document.createElement("script");
    script.src = url;
    document.getElementsByTagName('head')[0].appendChild(script);
    return script;
  }

  // include some css stylesheets in our bookmarklet
  function loadStyle(url) {
    var link  = document.createElement('link');
    link.type = 'text/css';
    link.href = url;
    link.rel  = 'stylesheet';
    document.getElementsByTagName('head')[0].appendChild(link);
  }

  function loadBookmarklet() {
    //loadScript("http://whattheme.5minutes.to/js/jquery.reveal.js");
    //loadScript("http://whattheme.5minutes.to/js/bookmarklet.js");
    loadStyle("http://fonts.googleapis.com/css?family=Droid+Serif:400,700");
    loadStyle("http://whattheme.5minutes.to/css/bookmarklet.css");
    whatthemeisit();
  }

  var head = document.getElementsByTagName('head')[0];
  // include jQuery and then load Bookmarklet
  if (window.jQuery === undefined || window.jQuery.fn.jquery < v) {
    var done = false;
    var script = document.createElement("script");
    script.src = "http://ajax.googleapis.com/ajax/libs/jquery/" + v + "/jquery.min.js";
    script.onload = script.onreadystatechange = function(){
      if (!done && (!this.readyState || this.readyState == "loaded" || this.readyState == "complete")) {
        done = true;
        loadBookmarklet();
      }
    };
    head.appendChild(script);
  } else {
    loadBookmarklet();
  }

  // the actual bookmarklet load happens here.
  function whatthemeisit() {
    (window.whattheme = function() {
      var response = '<div id="wtii_modal" style="display: none">' +
                     '<div id="wtii_heading">What Theme Analysis</div>' +
                     '<div id="wtii_content"><img src="http://whattheme.5minutes.to/img/ajaxloader.gif" id="wtii_loader"/></div>'+
                     '</div>'+
                     '<div id="wtii_reveal_modal_bg" style="display: none"></div>';
      if (jQuery("#wtii_modal") && jQuery("#wtii_modal").length > 0) jQuery("#wtii_modal").remove();
      if (jQuery("#wtii_reveal_modal_bg") && jQuery("#wtii_reveal_modal_bg").length > 0) jQuery("#wtii_reveal_modal_bg").remove();
      // console.log(response);
      jQuery(response).appendTo('body');
      jQuery("#wtii_reveal_modal_bg").fadeIn('slow', function() {
        jQuery("#wtii_modal").fadeIn('slow');
      });

      jQuery("#wtii_reveal_modal_bg").bind('click', function () {
        jQuery("#wtii_modal").fadeOut('slow', function() {
          jQuery("#wtii_reveal_modal_bg").fadeOut('slow');
        });
      });

      jQuery.ajax({
             url: 'http://whattheme.5minutes.to/theme?url=' + encodeURIComponent(document.URL),
        dataType: 'jsonp',
        success : function(data) {
                    if (data == undefined || data["message"] == undefined) {
                      data["message"] = "Could not find WordPress theme for this Site!";
                    }
                    jQuery("#wtii_content").html('<p>'+data["message"]+'</p>');
                  }
      });
    })();
  }
})();
