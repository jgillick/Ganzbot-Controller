
$(document).ready(function(){
  
/**
* Manage the message queues (new and history)
*/
var Queues = new (function(){
  var self = this;
  var queue, history;
  
  /**
  * Pause the update cycle on the queues
  */
  var paused = false;
  
  /**
  * The seconds between polling ajax requests
  */
  var pollTime = 5;
  
  /**
  * Poll for the next set of data, after the pollTime delay
  */
  function poll(){
    setTimeout(function(){
      if( !paused ){
        self.update();
      }
    }, pollTime * 1000);
  }
  
  /**
  * Pause the data polling
  */
  this.pausePolling = function(){
    self.paused = true;
  }
  
  /**
  * Resume the data polling
  */
  this.resumePolling = function(){
    self.paused = false;
    poll();
  }
  
  /**
  * Update both queue lists
  * @param {Object} data The JSON data with the queue lists (if null, the function will try to retrieve the data via XHR)
  */
  this.update = function(data){
    
    // Get the queue from the server
    if( !data ){
      jQuery.ajax({
        type: "get",
        dataType: "json",
        url: "/api.json",
        success: function(data){
          self.update(data);
        }
      });
    }
    
    // Load the lists
    if( typeof data == "object" && data.queue && data.history ){
      queue.html(buildList(data.queue));
      history.html(buildList(data.history));
    }
    
    poll();
  }
  
  /**
  * Build the queue or history list
  */  
  function buildList(list){
    var item, html = [];
    for( var i = 0, len = list.length; i < len; i++ ){
      item = list[i];
      html.push("<li>"+
			          " \"<span>"+ item.text +"</span>\""+
			          " <em>"+ item.time +"</em>"+
		            "</li>");
    }
    
    return html.join("");
  }

  queue = $("ol.queue");
  history = $("ol.history");
  
})();

  
  // Autofocus first message field
  var messageField = $(".message-field").get(0);
  if(messageField){
    messageField.focus();
  }
  
  // History actions
  $("ol.history").click(function(event){
    var trgt = event.target;
    var list = $(this);
    var item, message;
    
    item = (trgt.nodeName == "LI") ? $(trgt) : $(trgt).parent("li");
    if(!item.get(0)){
      return;
    }
    
    // Send the message
    message = item.find("span");
    if( message[0] ){
      Queues.pausePolling();
      item.addClass("progress");
      message = message[0].innerHTML;
      
      if( message == "" ){
        return;
      }
      
      jQuery.ajax({
        type: "post",
        url: "/add.awesome",
        dataType: "json",
        data: {"text": message, "responseType": "json"},
        success: function(data){
          Queues.update(data);
          Queues.resumePolling();
          item.removeClass("progress");
        },
        error: function(){
          Queues.resumePolling();
          item.removeClass("progress");
          alert("An error occurred");
        }
      });
    }
    
  });
  
  // Form submissions via XHR
  $("form").submit(function(){
    var form = this;
    var field = $(form).find(".message-field");
    var formData = $(form).serialize() + "&responseType=json";
  
    field.addClass("progress");
    jQuery.ajax({
        type: form.method,
        url: form.action,
        dataType: "json",
        data: formData,
        success: function(data){
          Queues.update(data);
          Queues.resumePolling();
          field.removeClass("progress");
          
          field = field.get(0);
          field.value = "";
          field.focus();
        },
        error: function(){
          Queues.resumePolling();
          field.removeClass("progress");
          alert("An error occurred");
        }
      }); 
    
    return false;
  });
  
})