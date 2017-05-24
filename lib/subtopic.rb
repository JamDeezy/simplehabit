# Straight up ruby script
require 'json'

file = File.read("#{Rails.root}/subtopics.json")
subtopics = JSON.parse(file)

Subtopic = {}
subtopics.each do |subtopic|
  Subtopic[subtopic["id"]] = subtopic["name"]
end