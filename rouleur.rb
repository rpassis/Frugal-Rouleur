require 'rubygems'
require 'haml'
require 'sass'
require 'sinatra'
require 'curb'
require 'nokogiri'
require 'maruku'
require 'open-uri'
require 'json'

configure :development do
  require "sinatra/reloader"
end

# Default is xhtml, do not want!
set :haml, {:format => :html5, :escape_html => false}





# Homepage
get '/' do
  # Render the HAML template
  haml :home
end

# Search results page
get '/search/:term' do
	
	# The search term
	search = params[:term];
	
  # Render the HAML template
  haml :home

end







# Takes in arguments for site, search term and number of results to return and returns JSON
# This will be called by JavaScript so that we can progressively show each site's results
get '/json/:site/:term/:number' do
	
	# We'll be returning JSON
	content_type 'application/javascript'
	
	# New JSON object for holding the results
	results = "["
	
	
	
	# Different rules for parsing the returned doc depending on the site
	if params[:site] == "Chain Reaction" then
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(open("http://www.chainreactioncycles.com/SearchResults.aspx?Search=" + params[:term]))
		
		# Loop through the number of items we want returned creating a little JSON object for each
		for i in 1..params[:number].to_i do
			results += "{"
			results += "\"name\": \"" + doc.css("#ModelLink#{i}")[0].attribute("title").value + "\","
			results += "\"price\": \"" + doc.css("#ModelPrice#{i} .Label11")[0].content.gsub(/Now\302\240\302\243/, '') + "\","
			results += "\"url\": \"" + "http://chainreactioncycles.com" + doc.css("#ModelLink#{i}")[0].attribute("href").value + "\","
			results += "\"image\": \"" + "http://chainreactioncycles.com" + doc.css("#ModelImageLink#{i} img")[0].attribute("src").value + "\""
			results += "},"
		end
		
	elsif params[:site] == "Wiggle" then
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(open("http://www.wiggle.co.uk/?s=" + params[:term]))
		
		# Loop through the number of items we want returned creating a little JSON object for each
		for i in 1..params[:number].to_i do
			results += "{"
			results += "\"name\": \"" + doc.css(".categoryListItem:nth-child(#{i}) h2 a")[0].content + "\","
			results += "\"price\": \"" + doc.css(".categoryListItem:nth-child(#{i}) .youpay strong")[0].content.gsub(/£/, '') + "\","
			results += "\"url\": \"" + doc.css(".categoryListItem:nth-child(#{i}) h2 a")[0].attribute("href").value + "\","
			results += "\"image\": \"" + doc.css(".categoryListItem:nth-child(#{i}) .productimage img")[0].attribute("src").value + "\""
			results += "},"
		end	
		
	elsif params[:site] == "ProBikeKit" then
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(open("http://www.probikekit.com/advsearch.php?AQUERY=" + params[:term]))
		
		# Loop through the number of items we want returned creating a little JSON object for each
		for i in 1..params[:number].to_i do
			results += "{"
			results += "\"name\": \"" + doc.css("form tr:nth-child(#{(i.to_f/2).round}) td[height='240']:nth-child(#{(i-1)%2 + 1}) a.PRODLINK")[0].content + "\","
			results += "\"price\": \"" + doc.css("form tr:nth-child(#{(i.to_f/2).round}) td[height='240']:nth-child(#{(i-1)%2 + 1}) span.nSmallNowOnly")[0].content.gsub(/Now Only £/, '') + "\","
			results += "\"url\": \"" + "http://www.probikekit.com/" + doc.css("form tr:nth-child(#{(i.to_f/2).round}) td[height='240']:nth-child(#{(i-1)%2 + 1}) a.PRODLINK")[0].attribute("href").value + "\","
			results += "\"image\": \"" + "http://www.probikekit.com/" + doc.css("form tr:nth-child(#{(i.to_f/2).round}) td[height='240']:nth-child(#{(i-1)%2 + 1}) img")[0].attribute("src").value + "\""
			results += "},"
		end	
		
	elsif params[:site] == "Ribble+Cycles" then
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(open("http://www.ribblecycles.co.uk/product/t/" + params[:term]))
		
	end
		
		
		
	
	# Chop off the last character and close the JSON
	return results.chop! << "]"
	
end







# Conversion of the SCSS to regular CSS
get '/style.css' do
  scss :style
end