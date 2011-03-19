require 'rubygems'
require 'haml'
require 'sass'
require 'sinatra'
require 'curb'
require 'nokogiri'
require 'maruku'
require 'open-uri'

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
	
	# Search URLs
	#sites = Hash[	"Chain Reaction" => "http://www.chainreactioncycles.com/SearchResults.aspx?Search=",
	#							"Wiggle" => "http://www.wiggle.co.uk/?s=",
	#							"ProBikeKit" => "http://www.probikekit.com/advsearch.php?AQUERY=",
	#							"Ribble Cycles" => "http://www.ribblecycles.co.uk/product/t/"]
	
	sites = Hash[	"Chain Reaction" => "http://www.chainreactioncycles.com/SearchResults.aspx?Search="]

	# New hash for holding the results
	results = Hash.new

	# Loop through each of the sites
	sites.each do |site, url| 
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(open(url + search))
		
		# Different rules for parsing the returned doc depending on the site
		if site == "Chain Reaction" then
			
			# Create hashes for the amount of results we want returned
			results["Chain Reaction"] = Array.new
			for i in 1..3 do
				results["Chain Reaction"][i] = Hash.new
				# Get the name, price, URL and image URL
				results["Chain Reaction"][i]["name"] 	= doc.css("#ModelLink#{i}")[0].attribute("title").value
				results["Chain Reaction"][i]["price"] 	= doc.css("#ModelPrice#{i} .Label11")[0].content.gsub(/Now\302\240\302\243/, '')
				results["Chain Reaction"][i]["url"] 		= "http://chainreactioncycles.com" + doc.css("#ModelLink#{i}")[0].attribute("href").value
				results["Chain Reaction"][i]["image"] 	= "http://chainreactioncycles.com" + doc.css("#ModelImageLink#{i} img")[0].attribute("src").value
			end
			
		elsif site == "Wiggle" then
			
		elsif site == "ProBikeKit" then
			
		elsif site == "Ribble Cycles" then
			
		end
		
	end

	puts results.inspect
	
  # Render the HAML template
  haml :home

end

# Takes in arguments for site, search term and number of results to return and returns JSON
# This will be called by JavaScript so that we can progressively show each site's results
get '/json/:site/:term/:number' do
	
end

# Conversion of the SCSS to regular CSS
get '/style.css' do
  scss :style
end