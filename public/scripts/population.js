// Abstracted this out into its own file because HAML doesn't do 
// syntax highlighting when you nest JavaScript under :javascript

$(function(){
	
	// Grab the search term
	var search = $("h2 em").text().replace(/\s/, "+");
	
	// Loop through each store making a JSON call to the search utility
	$(".result").each(function(){
		
		// Get the store name
		var store = $(this).find("h3 a").text().replace(/\s/, "+");
		
		// Set the holder for the appending of the results
		var result = $(this);
		
		// Make the AJAX call to grab the results
		$.get("/json/" + store + "/" + search + "/3", function(data){
			
			// If there's any results at all
			if (data.Results != "None") {
				
				// Start creating the holder
				var html = "<table>";
			
				// Loop through the results and form the HTML row
				for (var i=0; i < data.Results.length; i++) {
					html += "<tr>";
					html += "<td class='pic'><a href='" + data.Results[i].url + "'><img src='" + data.Results[i].image + "' alt='" + data.Results[i].name + "' /></a></td>";
					html += "<td class='title'><a href='" + data.Results[i].url + "'>" + data.Results[i].name + "</a></td>";
					html += "<td class='price'><span>AUD</span>" + data.Results[i].price + "</td>";
					html += "</tr>";
				};
			
				// Close up the HTML, remove the loading class and append it to the page
				html += "</table>";
				result.removeClass("loading");
				result.append(html);
				
			} else {
				
				// No results message
				result.removeClass("loading");
				result.append("<p class='noresults'>No Results");
				
			}
			
		}, "json");
		
	});
	
});