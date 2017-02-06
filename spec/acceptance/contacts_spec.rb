require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'uri'

def jsonish_attributes(record)
  pairs = record.attributes.except("id", "created_at", "updated_at")
  dash_keys = pairs.keys.map(&:dasherize)
  Hash[dash_keys.zip(pairs.values)]
end

def output_links
  links_to = JSON.parse(response_body)['data'].
               collect { |e| e['relationships'] }.
               collect(&:keys).flatten

  h = { "#{subject}" => links_to }
  p h
end

resource 'Contacts' do
  after(:each) do
    output_links
  end
  get '/contacts' do
    let!(:contact) { create(:contact) }
    let(:contact_representation) {
      {
        data: [
          {
            id: "1",
            links: {},
            attributes: jsonish_attributes(contact),
            relationships: {
              "phone-numbers" => {
                links: {
                  self: URI.regexp,
                  related: URI.regexp
                }
              }
            }
          }
        ]
      }
    }

    example 'Listing contacts' do
      do_request
      expect(status).to eq(200)
      expect(response_body).to include_json(contact_representation)
    end
  end
end
