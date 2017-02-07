require 'uri'
require 'ostruct'

def jsonish_attributes(record)
  pairs = record.attributes.except("id", "created_at", "updated_at")
  dash_keys = pairs.keys.map(&:dasherize)
  Hash[dash_keys.zip(pairs.values)]
end

SPLITTER = /(GET|POST|PUT|PATCH|DELETE) \/(.*)/
def parse(verb_path)
  verb, path = SPLITTER.match(verb_path)[1], SPLITTER.match(verb_path)[2]
  OpenStruct.new({verb: verb, path: path})
end

def link_relations
  Hash[*JSON.parse(response_body)['data'].
    collect { |e| e['relationships'] }.
    collect { |r| {"#{r.keys.first}" => r.values.first['links']['self']} }]
end

GRAPH_OUTPUT = "./spec/support/choclety/graph.json"
def output_links
  current_api_spec = JSON.parse(File.read(GRAPH_OUTPUT))
  links_to = JSON.parse(response_body)['data'].
               collect { |e| e['relationships'] }.
               collect(&:keys).flatten
  links = link_relations

  current_api_spec["state_transitions"] = [] if current_api_spec["state_transitions"].nil?
  links_to.each do |l|
    uri = URI(links[l])
    # in hash rocket format so uniqueness persists across, because parsing has string keys
    # while current entry would have symbol keys unless we manually make them strings
    current_api_spec["state_transitions"] << {
      'source' => parse(subject).path,
      'target' => l,
      'verb' => 'get',
      'link_relation' => uri.path,
      'url' => uri.to_s
    }
  end
  current_api_spec["state_transitions"] = current_api_spec["state_transitions"].uniq

  current_api_spec["state_representations"] = [] if current_api_spec["state_representations"].nil?
  links_to.each do |l|
    uri = URI(links[l])
    # in hash rocket format so uniqueness persists across, because parsing has string keys
    # while current entry would have symbol keys unless we manually make them strings
    current_api_spec["state_representations"] << { 'name' => parse(subject).path }
    current_api_spec["state_representations"] << { 'name' => l }
  end
  current_api_spec["state_representations"] = current_api_spec["state_representations"].uniq


  File.open(GRAPH_OUTPUT, "w+") { |file| file.write(current_api_spec.to_json) }

  h = { "#{subject}" => links_to }
  p h
end
