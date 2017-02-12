require 'uri'
require 'ostruct'

class ChocletyGenerator
  attr_reader :response_body, :subject
  attr_accessor :relationships, :types

  SUBJECT_SPLITTER = /(GET|POST|PUT|PATCH|DELETE) \/(.*)/
  PATH_SPLITTER = /.+(\/:.+)$/
  CONTAINS_RELATIONSHIPS = /(relationships\/.*)$/
  GRAPH_OUTPUT = './spec/support/choclety/graph.json'.freeze

  def initialize(response_body, subject)
    @response_body = response_body
    @subject = subject
  end

  def output_links
    current_api_spec = JSON.parse(File.read(GRAPH_OUTPUT))
    data = JSON.parse(response_body)['data']
    links_to = links_to(data)
    links = link_relations

    current_api_spec['state_transitions'] = [] if current_api_spec['state_transitions'].nil?
    links_to.each do |l|
      uri = URI(links[l])
      # in hash rocket format so uniqueness persists across, because parsing has string keys
      # while current entry would have symbol keys unless we manually make them strings
      current_api_spec['state_transitions'] << {
        'source' => parse(subject).path,
        'target' => l,
        'verb' => 'get',
        'link_relation' => abbreviate(uri.path),
        'url' => uri.to_s
      }
    end
    current_api_spec['state_transitions'] = current_api_spec['state_transitions'].uniq

    current_api_spec['state_representations'] = [] if current_api_spec['state_representations'].nil?
    links_to.each do |l|
      # in hash rocket format so uniqueness persists across, because parsing has string keys
      # while current entry would have symbol keys unless we manually make them strings
      current_api_spec['state_representations'] << { 'name' => parse(subject).path }
      current_api_spec['state_representations'] << { 'name' => l }
    end
    current_api_spec['state_representations'] = current_api_spec['state_representations'].uniq

    File.write(GRAPH_OUTPUT, JSON.pretty_generate(current_api_spec))

    p "Wrote choclety output to #{GRAPH_OUTPUT}"
  end

  private

  def parse(verb_path)
    verb = SUBJECT_SPLITTER.match(verb_path)[1]
    path = SUBJECT_SPLITTER.match(verb_path)[2]
    if ends_in_id?(path)
      # assumes immediate nesting is collection name
      path = path.split('/')[-2].singularize
    end
    OpenStruct.new(verb: verb, path: path)
  end

  def ends_in_id?(p)
    !!(p =~ PATH_SPLITTER)
  end

  def abbreviate(lr_path)
    if contains_relationships?(lr_path)
      lr_path.split('/')[-2..-1].join('/')
    else
      lr_path
    end
  end

  def contains_relationships?(p)
    !!(p =~ CONTAINS_RELATIONSHIPS)
  end

  def link_relations
    if relationships.is_a? Array
      Hash[*relationships.collect { |r| { r.keys.first.to_s => r.values.first['links']['self'] } }].merge(
        Hash[*types.collect { |t| { t => "http://example.org/#{t.pluralize}/1" } }])
    else
      {
        relationships.keys.first.to_s => relationships.values.first['links']['self'],
        types.first.to_s => "http://example.org/#{types.first.pluralize}/1"
      }
    end
  end

  def links_to(data)
    if data.is_a? Array
      @relationships = data.collect { |e| e['relationships'] }
      relationships = @relationships.collect(&:keys).flatten
      @types = data.collect { |e| e['type'] }.uniq.map(&:singularize)
      relationships + types
    else
      @relationships = data['relationships']
      @types = [data['type']].map(&:singularize)
      @relationships.keys.flatten + types
    end
  end
end
