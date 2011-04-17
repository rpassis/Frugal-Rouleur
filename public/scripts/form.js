$(function(){
	
	// Hold the suggestion outside the function so we can use it all over
	var randomSuggestion;
	
	// Generate a random suggestion
	function randomSuggester() {
		// Suggestions
		var suggestions = ["Look Pedals", "Dura-ace Chain", "Deda Bar Tape", "Super Record Cassette", "Taxc Bottle Cage", "Assos Arm Warmers", "Giro Ionos Helmet", "Sidi Ergo 2", "Garmin 800"];
		// Choose one
		randomSuggestion = suggestions[Math.floor(Math.random() * suggestions.length)];
		// Insert it 
		$("input[type=text]").val("eg. " + randomSuggestion);
	}
	
	// Call it on page load
	randomSuggester();
	
	// If the suggestion is in there on focus, remove it and give us black text
	$("input[type=text]").focus(function(){
		if ($("input[type=text]").val() == "eg. " + randomSuggestion) {
			$("input[type=text]").css({"color": "#383838"});
			$("input[type=text]").val("");
		}
	});
	
	// If they've entered a search term, leave it in there and leave it black, if it's blank
	// give them a new, greyed out, suggestion
	$("input[type=text]").blur(function(){
		if ($("input[type=text]").val() != "eg. " + randomSuggestion && $("input[type=text]").val() != "") {
			$("input[type=text]").css({"color": "#383838"});
		} else if ($("input[type=text]").val() == "") {
			$("input[type=text]").css({"color": "#BBB"});
			randomSuggester();
		}
	});
	
	// Nice button style
	$("input[type=submit]").mousedown(function(){
		$("input[type=submit]").css({"background": "-webkit-gradient(linear, left top, left bottom, color-stop(0%,#5F8246), color-stop(100%,#70C128))"});
	});
	$("input[type=submit]").mouseout(function(){
		$("input[type=submit]").css({"background": "-webkit-gradient(linear, left top, left bottom, color-stop(0%,#70C128), color-stop(100%,#5F8246))"});
	});
	
});