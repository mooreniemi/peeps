require 'rails_helper'
require 'rspec_api_documentation/dsl'

def jsonish_attributes(record)
  pairs = record.attributes.except("id", "created_at", "updated_at")
  dash_keys = pairs.keys.map(&:dasherize)
  Hash[dash_keys.zip(pairs.values)]
end

resource 'Contacts' do
  get '/contacts' do
    let!(:contact) { create(:contact) }
    example 'Listing contacts' do
      do_request
      expect(status).to eq(200)
      expect(response_body).
        to include_json(
             data: [
               {
                 id: "1",
                 links: {},
                 attributes: jsonish_attributes(contact),
                 relationships: {}
               }
             ]
           )
    end
  end
end
