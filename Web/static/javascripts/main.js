$(document).ready(function(){
  
  // Autofocus
  var messageField = document.getElementById("message-field");
  if(messageField){
    messageField.focus();
  }
  
  // History actions
  $("ol.history li").click(function(e){
    var message = $(this).find("span");
    
    // Send the message
    if( message[0] ){
      message = message[0].innerHTML;
      
      if( message == "" ){
        return;
      }
      
      jQuery.ajax({
        type: "post",
        url: "/add.awesome",
        data: {"text": message},
        success: function(){
          document.location.href = "/";
        },
        error: function(){
          alert("An error occurred");
        }
      });
    }
    
  });
  
})