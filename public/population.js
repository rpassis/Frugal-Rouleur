// Abstracted this out into its own file because HAML doesn't do 
// syntax highlighting when you nest JavaScript under :javascript

$(function(){
	
	// Grab the search term
	var search = $("h2 em").text().replace(/\s/, "+");
	// Loop through each store making a JSON call to the search utility
	$(".result").each(function(){
		var store = $(this).find("h3").text().replace(/\s/, "+");
		$.get("/json/" + store + "/" + search + "/1", function(data){
			console.log(data);
		}, "json");
	});
	
});