#!/usr/bin/ruby

## FCC Callsigns
# Downloads and parses the FCC Callsign Database
# Created By: Kevin Ashcraft (@kevashcraft)
# Created On: 12-05-2015
# Last Modified: 04-16-2016

require 'open-uri'
require 'fileutils'
require 'mysql'
require 'json'

$mydir = File.expand_path(File.dirname(__FILE__))

require "#{$mydir}/../DBConnection"

fcc_database_url = 'http://wireless.fcc.gov/uls/data/complete/l_amat.zip'

# Make Directories
FileUtils::mkdir_p "#{$mydir}/../tmp" if !File.directory?("#{$mydir}/../tmp")
FileUtils::mkdir_p "#{$mydir}/../tmp/fcc_database" if !File.directory?("#{$mydir}/../tmp/fcc_database")

# Download Database
unless File.exist?("#{$mydir}/../tmp/fcc_database/l_amat.zip")
	puts "Downloading Database"
	system "wget #{fcc_database_url} -P #{$mydir}/../tmp/fcc_database"
end

# Unzip
unless File.exist?("#{$mydir}/../tmp/fcc_database/EN.dat")
	puts "Unzipping.."
	system "unzip #{$mydir}/../tmp/fcc_database/l_amat.zip -d #{$mydir}/../tmp/fcc_database/"
end



# fcccallsign_add = DB.prepare "
# 	INSERT INTO FCCCallsigns (
# 			FCCCallsignULSID,
# 			FCCCallsign,
# 			FCCCallsignFirstName,
# 			FCCCallsignMiddleName,
# 			FCCCallsignLastName,
# 			FCCCallsignStreetAddress,
# 			ZipCodeID
# 		) SELECT
# 			?,
# 			?,
# 			?,
# 			?,
# 			?,
# 			?,
# 			ZipCodeID
# 			FROM ZipCodes WHERE ZipCode = ?
# 	"

callsign_update = DB.prepare "
	UPDATE FCCCallsigns
		SET
			FCCCallsignDateIssued = ?,
			FCCCallsignDateExpired = ?
		WHERE FCCCallsignULSID = ?
	"

DB.query "SET foreign_key_checks=0;"

# $callsigns = Hash.new
# times = 0
# File.open("#{$mydir}/../tmp/fcc_database/EN.dat", 'r:utf-8') do |f|
# 	f.each_line do |line|
# 		cleanedline = line.force_encoding('iso-8859-1').encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => "").chomp;
# 		# cleanedline = cleanedline.encode('UTF-8');
# 		puts "Line: #{cleanedline}"
# 		row = cleanedline.split('|')
# 		if row.length > 18 then
# 			ulsid = row[1]
# 			callsign = row[4].to_str
# 			callsignFirstName = row[8].to_str
# 			callsignMiddleName = row[9].to_str
# 			callsignLastName = row[10].to_str
# 			callsignStreetAddress = row[15].to_str
# 			callsignCity = row[16].to_str
# 			callsignState = row[17].to_str
# 			callsignZip = row[18][0..4].to_str

# 			fcccallsign_add.execute ulsid,callsign,callsignFirstName,callsignMiddleName,callsignLastName,callsignStreetAddress,callsignZip
# 			puts "Added to DB ULSID #{ulsid} - Callsign: #{callsign}: #{callsignFirstName} #{callsignLastName}"
# 		end
# 	end
# end

DB.query "COMMIT;"
File.open("#{$mydir}/../tmp/fcc_database/HD.dat", 'r') do |f|
	f.each_line do |line|
		row = line.force_encoding('iso-8859-1').encode('UTF-8', :invalid => :replace, :undef => :replace).chomp.split('|');
		ulsid = row[1];
		# $callsigns[ulsid] = Hash.new if !$callsigns[ulsid]
		# puts "Row7 #{row[7]}"

		if !row[7].empty? then
			puts " '#{row[7]}' "
			callsignDateIssued = Date.strptime(row[7], '%m/%d/%Y').strftime('%Y-%m-%d') if !row[7] != ''
		else
			callsignDateIssued = ''
		end
		if !row[8].empty? then
			puts " '#{row[8]}' "
			callsignDateExpired = Date.strptime(row[8], '%m/%d/%Y').strftime('%Y-%m-%d') if !row[8] != ''
		else
			callsignDateExpired = '';
		end
		callsign_update.execute callsignDateIssued, callsignDateExpired, ulsid
		puts "Updated USLID #{ulsid}"
	end
end
DB.query "COMMIT;"
