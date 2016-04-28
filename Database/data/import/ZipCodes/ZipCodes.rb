#!/usr/bin/ruby

# Downloads and parses the US Census Zipcode database
# Created On: 12-05-2015
# Created By: Kevin Ashcraft (@kevashcraft)
# Last Modified: 04-16-2016 by Kevin

require 'open-uri'
require 'fileutils'
require 'spreadsheet'


$mydir = File.expand_path(File.dirname(__FILE__))

require "#{$mydir}/../DBConnection"


census_zips_url = 'ftp://ftp.census.gov/econ2013/CBP_CSV/zbp13totals.zip'
census_states_url = 'https://www.census.gov/2010census/xls/fips_codes_website.xls'

FileUtils::mkdir_p "#{$mydir}/../tmp/census_data" if !File.directory?("#{$mydir}/../tmp/census_data")

unless File.exist?("#{$mydir}/../tmp/census_data/census_states.xls")
	puts "Downloading from #{census_states_url}"
	open("#{$mydir}/../tmp/census_data/census_states.xls", 'wb') do |file|
		file << open(census_states_url).read
	end
end

states_xls = Spreadsheet.open "#{$mydir}/../tmp/census_data/census_states.xls"
states_sheet = states_xls.worksheet 0

states = []
cities = []
counties = []
city_types = []

# ROWS
# 0:State Abbreviation
# 1:State FIPS Code
# 2:County FIPS Code
# 3:FIPS Entity Code
# 4:ANSI Code
# 5:GU Name (name)
# 6:Entity Description (type)

puts "Parsing xls file"
skip = true;
states_sheet.each do |row|
	if skip then
		skip = false
		next
	end

	# puts "Type #{row[6]}"
	if !row[6] && row[2] == '000' && row[3] == '00000' then
		states.push(row)
	elsif row[6] == 'County'
		counties.push(row)
	else
		city_types.push(row[6]) if !city_types.include?(row[6]) && row[6]
		cities.push(row)
	end
end

# p city_types
# die('as')
# prepare inserts

state_add = DB.prepare "
	INSERT INTO States ( State, StateAbbreviation, StateFIPS )
		VALUES (?, ?, ?)
		ON DUPLICATE KEY UPDATE StateID = LAST_INSERT_ID ( StateID )
"
county_add = DB.prepare "
	INSERT INTO Counties ( County, StateID, CountyFIPS )
		SELECT
				?, StateID, ?
			FROM States
			WHERE States.StateAbbreviation = ?
			ON DUPLICATE KEY UPDATE CountyID = LAST_INSERT_ID ( CountyID )
"

city_type_add = DB.prepare "
	INSERT INTO CityTypes ( CityType )
		VALUES ( ? )
		ON DUPLICATE KEY UPDATE CityTypeID = CityTypeID
"

city_add = DB.prepare "
	INSERT INTO Cities ( City, CityTypeID, StateID, CountyID, CityFIPS )
		SELECT
				?, CityTypeID, StateID, CountyID, ?
			FROM Counties
			LEFT JOIN CityTypes ON (CityTypes.CityType LIKE ?)
			WHERE Counties.CountyFIPS = ?
			ON DUPLICATE KEY UPDATE CityID = LAST_INSERT_ID ( CityID )
"

# iterate through states, counties, and cities

DB.query "SET foreign_key_checks=0;"


states.each do |row|
	state_add.execute row[5], row[0], row[1]
	puts "Adding State: #{row[5]}"
end
DB.query "COMMIT;"

counties.each do |row|
	county_add.execute row[5], row[2], row[0]
	puts "Adding County: #{row[5]}"
end
DB.query "COMMIT;"


city_types.each do |type|
	city_type_add.execute type
end
DB.query "COMMIT;"

cities.each do |row|
	city_add.execute row[5], row[3], row[6], row[2]
	puts "Adding City: #{row[5]}, #{row[0]}"
end
DB.query "COMMIT;"

if !File.exist?("#{$mydir}/../tmp/census_data/zbp13totals.txt") then
	if !File.exist?("#{$mydir}/../tmp/census_data/census_zips.zip") then
		puts "Downloading from #{census_zips_url}"
		open("#{$mydir}/../tmp/census_data/census_zips.zip", 'wb') do |file|
			file << open(census_zips_url).read
		end
	end
	if !File.exist?("#{$mydir}/../tmp/census_data/census_zips.zip") then
		puts "Unzipping.."
		system "unzip #{$mydir}/../tmp/census_data/census_zips.zip -d #{$mydir}/../tmp/census_data"
	end
end


# die('all done')


zip_add = DB.prepare "
	INSERT INTO ZipCodes ( ZipCode, CityID )
		SELECT
			?, CityID
		FROM States
		LEFT JOIN Cities ON Cities.StateID = States.StateID AND Cities.City LIKE ?
		WHERE States.StateAbbreviation = ?
"

File.open("#{$mydir}/../tmp/census_data/zbp13totals.txt", 'r') do |file|
	file.each_line do |line|
		zip = line.gsub('"','').split(',')

		zip_add.execute zip[0], zip[11], zip[12]
		puts "#{zip[11]}, #{zip[12]} - #{zip[0]} "
	end
end


DB.query "COMMIT;"
