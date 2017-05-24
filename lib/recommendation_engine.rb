require 'subtopic'
require 'json'

# coefficients
SAME_USER_COEFFICIENT = 1.2
MANY_USER_COEFFICIENT = 1.5

# Evaluation function
#
def evaluate_weight(user_counts)
  count = user_counts.values.reduce(0) do |sum, value|
    sum += value ** SAME_USER_COEFFICIENT
  end

  count + user_counts.keys.count ** MANY_USER_COEFFICIENT
end

# Return sorted array of subtopic UUIDs per subtopic
#
def sorted_recommended_topics(subtopic, users_listened_to_topic, topics_listened_by_user)
  all_user_that_listened_to_subtopic = users_listened_to_topic[subtopic]
  # In case a topic has no listens
  return [] if all_user_that_listened_to_subtopic.nil?

  all_topics_from_those_users = all_user_that_listened_to_subtopic.map { |listen|
    topics_listened_by_user[listen["user"]]
  }.flatten

  results = {}
  all_topics_from_those_users.each do |listen|
    results[listen["subtopic"]] ||= {}
    results[listen["subtopic"]][listen["user"]] ||=0
    results[listen["subtopic"]][listen["user"]] += 1
  end

  # Transform results into weights
  # Code smell - overwriting hash
  results.each{|k,v| results[k] = evaluate_weight(v) }.sort_by {|k,v| v}.reverse.map{|r| r[0] }
end

# Static map variable
#
MAP = Rails.cache.fetch("recommendation_map_7") do
  file = File.read("#{Rails.root}/listens.json")
  listens = JSON.parse(file)

  topics_listened_by_user = {}
  users_listened_to_topic = {}

  listens.each do |listen|
    # Changelog, push entire object
    topics_listened_by_user[listen["user"]] ||= []
    topics_listened_by_user[listen["user"]].push(listen)

    users_listened_to_topic[listen["subtopic"]] ||= []
    users_listened_to_topic[listen["subtopic"]].push(listen)
  end

  Hash[ Subtopic.keys.collect { |subtopic|
    [
      subtopic,
      sorted_recommended_topics(
        subtopic,
        users_listened_to_topic,
        topics_listened_by_user
      )
    ]
  }]
end

# Engine
#
module RecommendationEngine
  def self.recommend(subtopic)
    return [] if subtopic.empty?

    # Reject our query topic, take first 4
    MAP[subtopic].reject{ |st| st == subtopic}
      .first(4).map{ |st| Subtopic[st] }
  end
end