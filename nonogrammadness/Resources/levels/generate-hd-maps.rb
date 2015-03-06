#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'

# Get all map files in current directory
maps = Dir.glob('*.tmx')

maps.each { |filename|
  # Only process "sd" maps
  next if filename.index('-hd')

  # Determine base filename/extension
  filename_base, filename_extension = filename.split('.')

  # Open and parse file
  f = File.open(filename)
  document = Nokogiri::XML(f)
  f.close
  
  # Get the XML nodes that we need to modify
  map = document.at_css 'map'
  tileset = document.at_css 'tileset'
  image = document.at_css 'image'
  
  # Determine new tile size; since we use square tiles of one size, this is just multiplied by 2
  new_tile_size = String(map['tilewidth'].to_i * 2)
  new_spacing = String(tileset['spacing'].to_i * 2)
  new_margin = String(tileset['margin'].to_i * 2)
  
  # Set the new tile size
  map['tilewidth'] = map['tileheight'] = tileset['tilewidth'] = tileset['tileheight'] = new_tile_size

  # Set new margin/spacing
  tileset['spacing'] = new_spacing
  tileset['margin'] = new_margin
  
  # Append '-hd' to the tilemap image source
  # image_file_base, image_file_extension = image['source'].split('.')
  # image['source'] = image_file_base + '-hd.' + image_file_extension
    
  # Write the new file
  File.new(filename_base + '-hd.' + filename_extension, 'w').write document.to_xml unless document.validate
}