require 'uri'
require 'ostruct'

class ChocletyGenerator
  attr_reader :response_body, :subject
  attr_accessor :relationships

  SPLITTER = /(GET|POST|PUT|PATCH|DELETE) \/(.*)/
  GRAPH_OUTPUT = "./spec/support/choclety/graph.json"

  def initialize(response_body, subject)
    @response_body = response_body
    @subject = subject
  end

  def output_links
    current_api_spec = JSON.parse(File.read(GRAPH_OUTPUT))
    data = JSON.parse(response_body)['data']
    links_to = if data.is_a? Array
      @relationships = data.collect { |e| e['relationships'] }
      relationships.collect(&:keys).flatten
    else
      @relationships = data['relationships']
      relationships.keys.flatten
    end
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
      # in hash rocket format so uniqueness persists across, because parsing has string keys
      # while current entry would have symbol keys unless we manually make them strings
      current_api_spec["state_representations"] << { 'name' => parse(subject).path }
      current_api_spec["state_representations"] << { 'name' => l }
    end
    current_api_spec["state_representations"] = current_api_spec["state_representations"].uniq


    File.open(GRAPH_OUTPUT, "w+") { |file| file.write(current_api_spec.to_json) }

    p "Wrote choclety output to #{GRAPH_OUTPUT}"
  end

  private
  def parse(verb_path)
    verb, path = SPLITTER.match(verb_path)[1], SPLITTER.match(verb_path)[2]
    OpenStruct.new({verb: verb, path: path})
  end

  def link_relations
    if relationships.is_a? Array
      Hash[*relationships.collect { |r| {"#{r.keys.first}" => r.values.first['links']['self']} }]
    else
      { "#{relationships.keys.first}" => relationships.values.first['links']['self'] }
    end
  end
end
