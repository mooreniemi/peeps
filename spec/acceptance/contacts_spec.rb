require 'rails_helper'
require 'rspec_api_documentation/dsl'
require_relative '../support/choclety/choclety'

def jsonish_attributes(record)
  pairs = record.attributes.except('id', 'created_at', 'updated_at')
  dash_keys = pairs.keys.map(&:dasherize)
  Hash[dash_keys.zip(pairs.values)]
end

resource 'Contacts' do
  after(:each) do
    ChocletyGenerator.new(response_body.dup, subject.dup).output_links
  end

  get '/contacts' do
    let!(:contact) { create(:contact) }
    let(:contacts_representation) do
      {
        data: [
          {
            id: '1',
            type: 'contacts',
            links: {},
            attributes: jsonish_attributes(contact),
            relationships: {
              'phone-numbers' => {
                links: {
                  self: URI.regexp,
                  related: URI.regexp
                }
              }
            }
          }
        ]
      }
    end

    example 'Listing contacts' do
      do_request
      expect(status).to eq(200)
      expect(response_body).to include_json(contacts_representation)
    end
  end

  get '/contacts/:id' do
    let!(:contact) { create(:contact) }
    let(:id) { contact.id }
    let(:contact_representation) do
      {
        data:
          {
            id: '1',
            type: 'contacts',
            links: {},
            attributes: jsonish_attributes(contact),
            relationships: {
              'phone-numbers' => {
                links: {
                  self: URI.regexp,
                  related: URI.regexp
                }
              }
            }
          }
      }
    end

    example 'Showing contact' do
      do_request
      expect(status).to eq(200)
      expect(response_body).to include_json(contact_representation)
    end
  end
end
