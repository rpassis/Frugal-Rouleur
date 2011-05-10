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

# About page
get '/about' do
  # Render the HAML template
  haml :about
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
		connection.cookies = "UserSettings=GUID=4961162a-b9f0-45d4-9741-cc7b5f9f17dc&CurrencyISO=AUD&LanguageISO=en&NavigationID=0&PartnerID=0&PollID=0&PreferredUserLanguageISO=All&VatFree=True&ShippingCountryID=1712&ShowCategoryPictures=True&ListDisplayStyle=0&SuperCategoryID=2189&UseDefaultLanguage=True&Gender=0&PartnerIDExpiry=2011-05-15 08:12:57; expires=Thu, 12-May-2012 12:58:52 GMT; path=/; domain=www.chainreactioncycles.com; httponly"
		connection.http_get
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(connection.body_str)
		
		# Get the number of results found
		num_results = doc.css("#LblProductCount")[0].content.match(/Showing [0-9]+ \- [0-9]+ of ([0-9]+) Products/)[1]
		num_results_string = num_results.to_i == 1 ? num_results.to_s + " result" : num_results.to_s + " results"
		
		# Loop through the number of items we want returned creating a little JSON object for each
		for i in 1..params[:number].to_i do
			
			# If there's just one result the structure is a little different
			single_result = doc.css(".Div11").count == 1  ? true : false
			
			# Set the loop incrementing value
			increment = single_result ? i : (i+1)
			
			# Check that there's some results
			if (!doc.css("#Form1 table:nth-of-type(#{increment}) .Div11")[0].nil?) then

				# Create affiliate link
				# http://www.awin1.com/cread.php?awinmid=2698&awinaffid=121196&clickref=&p=http%3A%2F%2Fwww.chainreactioncycles.com%2FModels.aspx%3FModelID%3D51432
				link = "http://www.awin1.com/cread.php?awinmid=2698&awinaffid=121196&clickref=&p=http%3A%2F%2Fwww.chainreactioncycles.com" + doc.css("#Form1 table:nth-of-type(#{increment}) .Div11")[0].attribute("href").value.gsub(/\/Mobile\/MobileModels.aspx/, '/Models.aspx').gsub(/\:/, "%3A").gsub(/\//, "%2F")

				# Create object
				results += "{"
				results += "\"name\": \"" + doc.css("#Form1 table:nth-of-type(#{increment}) .Div11")[0].content + "\","
				results += "\"price\": \"" + doc.css("#Form1 table:nth-of-type(#{increment}) .Div12")[0].content.gsub(/Now |From |AUD/, '').strip + "\","
				results += "\"url\": \"" + link + "\","
				results += "\"image\": \"" + "http://chainreactioncycles.com" + doc.css("#Form1 table:nth-of-type(#{increment}) .Div29 img")[0].attribute("src").value + "\""
				results += "},"
				
			end
		end
		
	# ========================================================================
	# WIGGLE
	# ========================================================================
		
	elsif params[:site] == "Wiggle" then
		
		# User Curb so we can pass in the cookie data
		connection = Curl::Easy.new
		connection.url = "http://www.wiggle.co.uk/?s=" + search
		connection.cookies = "browsingCustomer2=Name=&DType=None&CID=0&Last=15/04/2011 08:33:08&Cur=AUD&Dest=27&Language=en&SiteDomainName=wiggle.co.uk; expires=Thu, 12-May-2012 12:58:52 GMT; path=/; domain=www.wiggle.co.uk/; httponly"
		connection.http_get
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(connection.body_str)
		
		# Loop through the number of items we want returned creating a little JSON object for each
		for i in 1..params[:number].to_i do
			# Check that there's some results
			if (!doc.css(".categoryListItem:nth-child(#{i})")[0].nil?) then
				
				# Create affiliate link
				# http://www.awin1.com/cread.php?awinmid=1857&awinaffid=121196&clickref=&p=http%3A%2F%2Fwww.wiggle.co.uk%2Fgarmin-edge-500-with-heart-rate-and-cadence%2F
				link = "http://www.awin1.com/cread.php?awinmid=1857&awinaffid=121196&clickref=&p=" + doc.css(".categoryListItem:nth-child(#{i}) h2 a")[0].attribute("href").value.gsub(/\:/, "%3A").gsub(/\//, "%2F")
				
				# Create object
				results += "{"
				results += "\"name\": \"" + doc.css(".categoryListItem:nth-child(#{i}) h2 a")[0].content + "\","
				results += "\"price\": \"" + doc.css(".categoryListItem:nth-child(#{i}) .youpay strong")[0].content.gsub(/\$/, '') + "\","
				results += "\"url\": \"" + link + "\","
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
				
				results += "\"url\": \"http://scripts.affiliatefuture.com/AFClick.asp?affiliateID=252357&merchantID=4100&programmeID=10236&mediaID=0&tracking=&url=" + item.css(".product-name a")[0].attribute("href").value + "\","
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
		
		# Create and grab the search results
		# Unfortunuately Ribble does some weird server side thing to remember your current location and currency
		# The change currency page returns a 301 permanent redirect which redirects properly in a browser but I 
		# can't get Curl to do it. Oh well.
		connection = Curl::Easy.new
		# connection.url = "http://www.ribblecycles.co.uk/ChangeCurrency.asp?C=AUD&CC=AU&from=http://www.ribblecycles.co.uk/product/t/" + search
		connection.url = "http://www.ribblecycles.co.uk/product/t/" + search
		connection.http_get
		
		# Parse the doc into Nokogiri
		doc = Nokogiri::HTML(connection.body_str)
		
		# Loop through the number of items we want returned creating a little JSON object for each
		for i in 1..params[:number].to_i do
			# Check that there's some results
			if (!doc.css("#listItemTitle#{i}")[0].nil?) then
				
				# Convert the price to AUD
				amount = doc.css(".productListItem:nth-child(#{(i*2)-1}) .price4")[0].content.gsub(/£([0-9]+\.[0-9]+) a saving of [0-9]+\.[0-9]+%/, '\1').strip.to_f * 0.8
				currency = open("http://www.google.com/ig/calculator?hl=en&q=" + amount.to_s  + "GBP%3D%3FAUD")	
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
		if num_results then
			return results.chop! << "], \"Number\": \"" + num_results + "\", \"NumberString\": \"" + num_results_string + "\"}"
		else
			return results.chop! << "]}"
		end
	end
	
end