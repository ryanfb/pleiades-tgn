#!/usr/bin/env ruby

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'json'
require 'csv'

tgn_labels_nt, tgn_geometries_nt, places_csv, names_csv = ARGV

distance_threshold = 8.0

places = {}
pleiades_names = {}

def haversine_distance(lat1, lon1, lat2, lon2)
  km_conv = 6371 # km
  dLat = (lat2-lat1) * Math::PI / 180
  dLon = (lon2-lon1) * Math::PI / 180
  lat1 = lat1 * Math::PI / 180
  lat2 = lat2 * Math::PI / 180

  a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2)
  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  d = km_conv * c
end

$stderr.puts "Parsing Pleiades places..."
CSV.foreach(places_csv, :headers => true) do |row|
  places[row["id"]] = row.to_hash
end

$stderr.puts "Parsing Pleiades names..."
CSV.foreach(names_csv, :headers => true) do |row|
  unless places[row["pid"]].nil?
    places[row["pid"]]["names"] ||= []
    places[row["pid"]]["names"] << row.to_hash
  end

  [row["title"], row["nameAttested"], row["nameTransliterated"]].each do |name|
    pleiades_names[name] ||= []
    pleiades_names[name] << row["pid"] unless (pleiades_names[name].include?(row["pid"]) || row["pid"].nil?)
  end
end
$stderr.puts pleiades_names.keys.length

tgn_labels = {}
tgn_first_label = {}

$stderr.puts "Parsing TGN labels..."
File.open(tgn_labels_nt).each do |line|
  subject, predicate, object = line.split(' ')
  tgn_toponym = object[/"(.+)"/,1]
  unless tgn_toponym.nil?
    tgn_toponym.gsub!(/\\u(.{4})/) {|m| [$1.to_i(16)].pack('U')}
    tgn_labels[tgn_toponym] ||= []
    tgn_labels[tgn_toponym] << subject
    tgn_first_label[subject] ||= tgn_toponym
  end
end
$stderr.puts tgn_labels.keys.length

tgn_geometries = {}

$stderr.puts "Parsing TGN geometries..."
File.open(tgn_geometries_nt).each do |line|
  subject, predicate, object = line.split(' ')
  tgn_geometries[subject] ||= {}
  if predicate == '<http://schema.org/latitude>'
    tgn_geometries[subject][:latitude] = object[/"(.+)"/,1].to_f
  elsif predicate == '<http://schema.org/longitude>'
    tgn_geometries[subject][:longitude] = object[/"(.+)"/,1].to_f
  end
end
$stderr.puts tgn_geometries.keys.length

$stderr.puts "Checking matches..."
pleiades_names.each do |pleiades_name, pleiades_ids|
  unless pleiades_name.nil? || pleiades_name.empty?
    if tgn_labels.has_key?(pleiades_name)
      tgn_labels[pleiades_name].each do |tgn_id|
        geometry_subject = tgn_id.sub('>','-geometry>')
        if tgn_geometries.has_key?(geometry_subject)
          geometry = tgn_geometries[geometry_subject]
          pleiades_ids.each do |pleiades_id|
            unless places[pleiades_id].nil? || geometry.nil?
              if haversine_distance(geometry[:latitude], geometry[:longitude], places[pleiades_id]["reprLat"].to_f, places[pleiades_id]["reprLong"].to_f) <= distance_threshold
                puts [tgn_id.tr('<>',''),"http://pleiades.stoa.org/places/#{pleiades_id}",tgn_first_label[tgn_id]].join(',')
              end
            end
          end
        end
      end
    end
  end
end
