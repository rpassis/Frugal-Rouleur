# encoding: utf-8

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



# Conversion of the SCSS to regular CSS
get '/style.css' do
  scss :style
end

# Homepage
get '/' do
  # Render the HAML template
  haml :home
end

# Process a search perform
post '/search' do
	
	# Convert the search term and redirect
	redirect to('/search/' + params[:term].gsub(/\s/,'+'))
	
end
	

# Search results page
get '/search/:term' do
	
	# The search term
	@search = params[:term].gsub(/\+/, ' ')
	@searchconcat = params[:term]
	
  # Render the HAML template
  haml :search

end



# Takes in arguments for site, search term and number of results to return and returns JSON
# This will be called by JavaScript so that we can progressively show each site's results
get '/json/:site/:term/:number' do
	
	# We'll be returning JSON
	content_type 'application/javascript'
	
	# New JSON object for holding the results
	results = "{\"Results\": ["
	
	# Multi-word search term parsing
	search = params[:term].gsub(/\s/, "+")
	
	# ========================================================================
	# CHAIN REACTION
	# ========================================================================
	
	# Different rules for parsing the returned doc depending on the site
	if params[:site] == "Chain Reaction" then

		# For chain reaction we have to use curb because it doesn't return
		# images if we don't specify a graphical user agent
		connection = Curl::Easy.new
		connection.useragent = "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_1 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8B117 Safari/6531.22.7"
		connection.url = "http://www.chainreactioncycles.com/Mobile/MobileSearchResults.aspx?Search=" + search
		connection.http_get
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(connection.body_str)
		
		# Loop through the number of items we want returned creating a little JSON object for each
		for i in 1..params[:number].to_i do
			# Check that there's some results
			# if (!doc.css("#ModelLink#{i}")[0].nil?) then
			if (!doc.css(".Div29")[0].nil?) then
				
				# Convert the price to AUD
				currency = open("http://www.google.com/ig/calculator?hl=en&q=" + doc.css("#Form1 table:nth-of-type(#{i+1}) .Div12")[0].content.gsub(/Now £|From £/, '') + "GBP%3D%3FAUD")	
				australian = (currency.string.match(/([0-9]+.[0-9]+) Australian dollars/)[1].to_f * 100).round/100.00
				
				# Create object
				results += "{"
				results += "\"name\": \"" + doc.css("#Form1 table:nth-of-type(#{i+1}) .Div11")[0].content + "\","
				results += "\"price\": \"" + australian.to_s + "\","
				results += "\"url\": \"" + "http://chainreactioncycles.com" + doc.css("#Form1 table:nth-of-type(#{i+1}) .Div11")[0].attribute("href").value.gsub(/\/Mobile\/MobileModels.aspx/, '/Models.aspx') + "\","
				results += "\"image\": \"" + "http://chainreactioncycles.com" + doc.css("#Form1 table:nth-of-type(#{i+1}) .Div29 img")[0].attribute("src").value + "\""
				results += "},"
				
			end
		end
		
	# ========================================================================
	# WIGGLE
	# ========================================================================
		
	elsif params[:site] == "Wiggle" then
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(open("http://www.wiggle.co.uk/?s=" + search))
		
		# Loop through the number of items we want returned creating a little JSON object for each
		for i in 1..params[:number].to_i do
			# Check that there's some results
			if (!doc.css(".categoryListItem:nth-child(#{i})")[0].nil?) then
				
				# Convert the price to AUD
				currency = open("http://www.google.com/ig/calculator?hl=en&q=" + doc.css(".categoryListItem:nth-child(#{i}) .youpay strong")[0].content.gsub(/£/, '') + "GBP%3D%3FAUD")	
				australian = (currency.string.match(/([0-9]+.[0-9]+) Australian dollars/)[1].to_f * 100).round/100.00
				
				# Create object
				results += "{"
				results += "\"name\": \"" + doc.css(".categoryListItem:nth-child(#{i}) h2 a")[0].content + "\","
				results += "\"price\": \"" + australian.to_s + "\","
				results += "\"url\": \"" + doc.css(".categoryListItem:nth-child(#{i}) h2 a")[0].attribute("href").value + "\","
				results += "\"image\": \"" + doc.css(".categoryListItem:nth-child(#{i}) .productimage img")[0].attribute("src").value + "\""
				results += "},"
				
			end
		end	
	
	# ========================================================================
	# PRO BIKE KIT
	# ========================================================================
	
	elsif params[:site] == "ProBikeKit" then
		
		# For PBK we have to use curb because we have to send the search term as a POST var
		connection = Curl::Easy.new
		connection.url = "http://www.probikekit.com/au/factfinder/search/result/?q=" + search
		connection.cookies = "geolc=aud; expires=Thu, 12-May-2011 12:58:52 GMT; path=/; domain=www.probikekit.com; httponly"
		connection.http_get
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(connection.body_str).css(".item")
		
		# Loop through the number of items we want returned creating a little JSON object for each
		for i in 1..params[:number].to_i do
			# Check that there's some results
			if (!doc.css(".item")[0].nil?) then
				
				# Get the right item
				item = doc.css(".item")[i-1]
				
				# Create object
				results += "{"
				results += "\"name\": \"" + item.css(".product-name a")[0].content + "\","
				
				# Sometimes the price element is different for unknown reasons
				if (item.css(".price")[0].nil?)
					results += "\"price\": \"" + item.css(".price_actual")[0].content.strip.gsub!(/AU\$/, '') + "\","
				else
					results += "\"price\": \"" + item.css(".price")[0].content.strip.gsub!(/AU\$/, '') + "\","
				end
				
				results += "\"url\": \"" + item.css(".product-name a")[0].attribute("href").value + "\","
				results += "\"image\": \"" + item.css(".product-image img")[0].attribute("src").value + "\""
				results += "},"
				
			end
		end	
		
	# ========================================================================
	# RIBBLE CYCLES
	# ========================================================================
		
	elsif params[:site] == "Ribble Cycles" then
		
		# Multi-word search term parsing
		search.gsub!(/\+/, "%20")
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(open("http://www.ribblecycles.co.uk/product/t/" + search))
		
		# Loop through the number of items we want returned creating a little JSON object for each
		for i in 1..params[:number].to_i do
			# Check that there's some results
			if (!doc.css("#listItemTitle#{i}")[0].nil?) then
				
				# Convert the price to AUD
				currency = open("http://www.google.com/ig/calculator?hl=en&q=" + doc.css(".productListItem:nth-child(#{(i*2)-1}) .price4")[0].content.gsub(/£([0-9]+\.[0-9]+) a saving of [0-9]+\.[0-9]+%/, '\1').strip + "GBP%3D%3FAUD")	
				australian = (currency.string.match(/([0-9]+.[0-9]+) Australian dollars/)[1].to_f * 100).round/100.00
				
				# Create object
				results += "{"
				results += "\"name\": \"" + doc.css("#listItemTitle#{i}")[0].content + "\","
				results += "\"price\": \"" + australian.to_s + "\","
				results += "\"url\": \"" + doc.css("#listItemTitle#{i}")[0].attribute("href").value + "\","
				results += "\"image\": \"" + doc.css("#pimage#{i}")[0].attribute("data-src").value + "\""
				results += "},"
				
			end
		end	
		
	end
	
	# Check for results and return
	if results == "{\"Results\": [" then
		return "{\"Results\": \"None\"}"
	else	
		return results.chop! << "]}"
	end
	
end







