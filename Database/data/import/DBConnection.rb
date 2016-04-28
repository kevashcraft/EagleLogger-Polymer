#!/usr/bin/ruby

## DB Connection
# Establishes a global connection to the database

require 'mysql'

# db configuration
DB_host = 'localhost'
DB_database = 'EagleLogger'
DB_username = 'EagleLogger'
DB_password = 'EagleLogger'

# create db connection
DB = Mysql.new DB_host, DB_username, DB_password, DB_database
