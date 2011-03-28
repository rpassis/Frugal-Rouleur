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

# Search results page
get '/search/:term' do
	
	# The search term
	@search = params[:term].gsub(/\+/, ' ');
	
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
	
	# Different rules for parsing the returned doc depending on the site
	if params[:site] == "Chain Reaction" then

		# For chain reaction we have to use curb because it doesn't return
		# images if we don't specify a graphical user agent
		connection = Curl::Easy.new
		connection.useragent = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-us) AppleWebKit/533.20.25 (KHTML, like Gecko) Version/5.0.4 Safari/533.20.27"
		connection.url = "http://www.chainreactioncycles.com/SearchResults.aspx?Search=" + search
		connection.http_get
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(connection.body_str)
		
		# Loop through the number of items we want returned creating a little JSON object for each
		for i in 1..params[:number].to_i do
			# Check that there's some results
			if (!doc.css("#ModelLink#{i}")[0].nil?) then
				
				# Convert the price to AUD
				currency = open("http://www.google.com/ig/calculator?hl=en&q=" + doc.css("#ModelPrice#{i} .Label11")[0].content.gsub(/Now\302\240\302\243/, '') + "GBP%3D%3FAUD")	
				australian = (currency.string.match(/([0-9]+.[0-9]+) Australian dollars/)[1].to_f * 100).round/100.00
				
				# Create object
				results += "{"
				results += "\"name\": \"" + doc.css("#ModelLink#{i}")[0].attribute("title").value + "\","
				results += "\"price\": \"" + australian.to_s + "\","
				results += "\"url\": \"" + "http://chainreactioncycles.com" + doc.css("#ModelLink#{i}")[0].attribute("href").value + "\","
				puts "============================"
				puts doc.css("#ModelImageContainer#{i}").to_s
				puts "============================"
				results += "\"image\": \"" + "http://chainreactioncycles.com" + doc.css("#ModelImageContainer#{i}")[0].attribute("style").value.match(/background\-image\:url\((.+\.jpg)\);/)[1] + "\""
				results += "},"
				
			end
		end
		
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
		
	elsif params[:site] == "ProBikeKit" then
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(open("http://www.probikekit.com/advsearch.php?AQUERY=" + search))
		
		# Loop through the number of items we want returned creating a little JSON object for each
		for i in 1..params[:number].to_i do
			# Check that there's some results
			if (!doc.css("form tr:nth-child(#{(i.to_f/2).round}) td[height='240']:nth-child(#{(i-1)%2 + 1})")[0].nil?) then
				
				# Convert the price to AUD
				currency = open("http://www.google.com/ig/calculator?hl=en&q=" + doc.css("form tr:nth-child(#{(i.to_f/2).round}) td[height='240']:nth-child(#{(i-1)%2 + 1}) span.nSmallNowOnly")[0].content.gsub(/Now Only £/, '') + "GBP%3D%3FAUD")	
				australian = (currency.string.match(/([0-9]+.[0-9]+) Australian dollars/)[1].to_f * 100).round/100.00
				
				# Create object
				results += "{"
				results += "\"name\": \"" + doc.css("form tr:nth-child(#{(i.to_f/2).round}) td[height='240']:nth-child(#{(i-1)%2 + 1}) a.PRODLINK")[0].content + "\","
				results += "\"price\": \"" + australian.to_s + "\","
				results += "\"url\": \"" + "http://www.probikekit.com/" + doc.css("form tr:nth-child(#{(i.to_f/2).round}) td[height='240']:nth-child(#{(i-1)%2 + 1}) a.PRODLINK")[0].attribute("href").value + "\","
				results += "\"image\": \"" + "http://www.probikekit.com/" + doc.css("form tr:nth-child(#{(i.to_f/2).round}) td[height='240']:nth-child(#{(i-1)%2 + 1}) img")[0].attribute("src").value + "\""
				results += "},"
				
			end
		end	
		
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







