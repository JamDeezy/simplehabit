# Simple approach
````
topics_listened_by_user = {
    user_id: [listened_to]
}

users_listened_to_topic = {
    subtopic: [listened_by]
}
````

# want recommendation for <subtopic>
1) find `users` that listened to `subtopic` with `users_listened_to_topic`
2) create count of number of times `subtopics` appeared in `users` with `topics_listened_by_user`
3) return top 4

# Pseudo
````
topics_listened_by_user = {
    a: [1,4,5],
    b: [1,3,5],
    c: [2,3,5]
}
users_listened_to_topic = {
    1: [a, b],
    2: [c],
    3: [b, c],
    4: [a],
    5: [a, b, c]
}

all_user_that_listened_to_subtopic = users_listened_to_topic[subtopic]
all_other_subtopics_from_those_users = all_user_that_listened_to_subtopic.map{
  |user| topics_listened_by_user[user].reject(subtopic)
}.flatten

results = {}
all_other_subtopics_from_those_users.each do |subtopic|
  results[subtopic] ||= 0
  results[subtopic] += 1
end

results.sort_by {|k,v| v}.reverse.first(4).map{|r| r[0] }
````

# Optimization
````
# We can first backprocess the work done with `topics_listened_by_user` and `users_listened_to_topic`
c_map = {
  topic: [ top_recommended, 2nd_recommended... ]
}
# Then our request is O(1) time that looks like
c_map[topic].first(4)

# To generate this c_map, we can do the algorithm before for every topic
````

# Pseudo II
````
topics_listened_by_user = {
    a: [1,4,5],
    b: [1,3,5],
    c: [2,3,5]
}
users_listened_to_topic = {
    1: [a, b],
    2: [c],
    3: [b, c],
    4: [a],
    5: [a, b, c]
}

def sorted_recommended_topics(topic)
  all_user_that_listened_to_subtopic = users_listened_to_topic[subtopic]
  all_other_subtopics_from_those_users = all_user_that_listened_to_subtopic.map{
    |user| topics_listened_by_user[user].reject(subtopic)
  }.flatten

  results = {}
  all_other_subtopics_from_those_users.each do |subtopic|
    results[subtopic] ||= 0
    results[subtopic] += 1
  end

  results.sort_by {|k,v| v}.reverse.map{|r| r[0] }
end

c_map = Hash[users_listened_to_topic.keys.collect{ |k| [k, sorted_recommended_topics(k)] }]
````

# Optimization II
````
# the backprocess script could be optimized (faster run time means we can update recommendations more frequently)

def sorted_recommended_topics(topic)
  all_user_that_listened_to_subtopic = users_listened_to_topic[subtopic]                    # O(1)
  all_other_subtopics_from_those_users = all_user_that_listened_to_subtopic.map{            # O(n)
    |user| topics_listened_by_user[user].reject(subtopic)                                   # --O(n)
  }.flatten                                                                                 # O(n)

  results = {}
  all_other_subtopics_from_those_users.each do |subtopic|                                   # O(n)
    results[subtopic] ||= 0                                                                 # O(1)
    results[subtopic] += 1
  end

  results.sort_by {|k,v| v}.reverse.map{|r| r[0] }                                          # Assume fastest sort is O(nlogn)
end

# We're looking at an O(n^2) run time because we have to reject(subtopic) inside of a loop,

# What if we just return subtopic as part of the choices and ignore it as part of our return?

def sorted_recommended_topics(topic)
  all_user_that_listened_to_subtopic = users_listened_to_topic[subtopic]                    # O(1)
  all_topics_from_those_users = all_user_that_listened_to_subtopic.map{                     # O(n)
    |user| topics_listened_by_user[user]                                                    #   O(1)
  }.flatten                                                                                 # O(n)

  results = {}
  all_other_subtopics_from_those_users.each do |subtopic|                                   # O(n)
    results[subtopic] ||= 0                                                                 # O(1)
    results[subtopic] += 1
  end

  results.sort_by {|k,v| v}.reverse.map{|r| r[0] }                                          # Assume fastest sort is O(nlogn)
end

# Now we have an O(nlogn) solution
````

# Optimization III
````
# Previously, we assumed we're given hashmaps `topics_listened_by_user` & `users_listened_to_topic`
# Lets generate those hashes

topics_listened_by_user = {}, users_listened_to_topic = {}

# O(n)
listens.each do |listen|
  topics_listened_by_user[listen.user] ||= []
  topics_listened_by_user[listen.user].push(listen.subtopic)
end

listens.each do |listen|
  users_listened_to_topic[listen.subtopic] ||= []
  users_listened_to_topic[listen.subtopic].push(listen.user)
end

# Now we're missing the mapping of subtopic UUID to subtopic NAME,
# Personally, I feel that subtopic maping of UUID and NAME should be persisted through database,
# We'll generate a hash to mimic that db, so that we can maintain our O(1) response speed
subtopic_map = {}
subtopics.each do |subtopic|
  subtopic_map[subtopic.id] = subtopic.name
end
````

Q: How does duplicate listens affect the engine?

A) it doesnt

B) it does -> frequency has linear affect on engine (duplicate listens have equal weight)

C) it does -> frequency has diminishing affect on engine (duplicate listens have less weight by some f(x))

D) it does -> frequency has increased affect on engine (duplicate listens has increasing weight by some f(x))

````
# Personally, I think D) makes the most sense as we place maximum value on user understanding of what is recommended
# We can then replace the end result before easily with a function of our choice
# I think a polynomial scale will work fine, as this is to showcase ease of refactorability

COEFFICIENT = 1
def evaluate_weight(cur_count)
  return cur_count ^ COEFFICIENT * 2
end

# however we could gather additional user behaviour based on how much they liked a recommendation base on metrics like
#  - did they quit the recommendation before it finished?
#  - did they finish the recommendation?
#  - did they continue to another recommendation?
#
# I expect that there would be a significant fall off for each subsequent recommendation, kind of like a staircase
# We can re-evaluate the weighing function by A/B testing differing coefficients and its affects on the drop off.
````