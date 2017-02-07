require 'rails_helper'
require 'rspec_api_documentation/dsl'
require_relative '../support/choclety/choclety'

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
