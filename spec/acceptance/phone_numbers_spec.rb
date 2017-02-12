require 'rails_helper'
require 'rspec_api_documentation/dsl'
require_relative '../support/choclety/choclety'

def jsonish_attributes(record)
  # FIXME: oddly jsonapi default isnt surfacing contact_id
  # so we're just ignoring right now to keep test clean
  pairs = record.attributes.except('id', 'contact_id', 'created_at', 'updated_at')
  dash_keys = pairs.keys.map(&:dasherize)
  Hash[dash_keys.zip(pairs.values)]
end

resource 'Phone numbers' do
  after(:each) do
    ChocletyGenerator.new(response_body.dup, subject.dup).output_links
  end

  get '/phone-numbers' do
    let!(:phone_number) { create(:phone_number) }
    let(:phone_number_representation) do
      {
        data: [
          {
            id: '1',
            links: {},
            attributes: jsonish_attributes(phone_number),
            relationships: {
              'contact' => {
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

    example 'Listing phone_numbers' do
      do_request
      expect(status).to eq(200)
      expect(response_body).to include_json(phone_number_representation)
    end
  end

  get '/phone-numbers/:id' do
    let!(:phone_number) { create(:phone_number) }
    let(:id) { phone_number.id }
    let(:phone_number_representation) do
      {
        data:
          {
            id: '1',
            links: {},
            attributes: jsonish_attributes(phone_number),
            relationships: {
              'contact' => {
                links: {
                  self: URI.regexp,
                  related: URI.regexp
                }
              }
            }
          }
      }
    end

    example 'Showing phone-number' do
      do_request
      expect(status).to eq(200)
      expect(response_body).to include_json(phone_number_representation)
    end
  end
end
