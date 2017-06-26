require 'elasticsearch'
require 'json'
require 'parallel'
require 'csv'
require 'securerandom'
require 'time'

INDEX = 'tagging-events'
AWS_SERVICE = 'search-govuk-tagging-experiment-sl2zmv5puyjarpygspqdsa33n4.eu-west-2.es.amazonaws.com'

class Hash
  def slice(*keys)
    keys.map! { |key| convert_key(key) } if respond_to?(:convert_key, true)
    keys.each_with_object(self.class.new) { |k, hash| hash[k] = self[k] if has_key?(k) }
  end
end

transport = Elasticsearch::Transport::Transport::HTTP::Faraday.new(
  hosts: [{
    scheme: 'https',
    host: AWS_SERVICE,
    port: '443',
  }]
)

client = Elasticsearch::Client.new(transport: transport)

begin
  client.indices.delete(index: INDEX)
rescue
end

# https://www.elastic.co/guide/en/elasticsearch/guide/current/mapping-intro.html

IDENTIFIER = {
  type: "string",
  index: "not_analyzed",
}

DATE = {
  type: "date",
  index: "not_analyzed",
}

TEXT = {
  type: "string",
  index: "analyzed",
}

INTEGER = {
  type: "integer",
}

MAPPINGS = {
  taggable_content_id: IDENTIFIER,
  taggable_title: IDENTIFIER,
  taggable_navigation_document_supertype: IDENTIFIER,
  taggable_base_path: IDENTIFIER,
  tagged_at: DATE,
  tagged_on: DATE,
  user_uid: IDENTIFIER,
  taxon_content_id: IDENTIFIER,
  taxon_title: IDENTIFIER,
  change: INTEGER,
  user_name: IDENTIFIER,
  user_organisation: IDENTIFIER,
}

client.indices.create(
  index: INDEX,
  body: {
    mappings: {
      page: {
        properties: MAPPINGS
      }
    }
  }
)

done = 0

users = JSON.parse(File.read('users.json'))

rows = []

CSV.foreach('events.csv', headers: true) do |row|
  rows << row
end

Parallel.each(rows, in_threads: 50) do |row|
  # Only insert things that we've typed
  payload = row.to_h.slice(*MAPPINGS.keys.map(&:to_s))

  user = users.find do |u|
    u["user_uid"] == payload["user_uid"]
  end || {}

  payload[:user_name] = user["name"]
  payload[:user_organisation] = user["organisation"]
  payload["tagged_at"] = Time.parse(payload["tagged_at"]).iso8601
  puts payload
  client.index(
    index: INDEX,
    type: 'page',
    id: SecureRandom.uuid,
    body: payload,
  )

  done = done + 1

  puts "#{done} Indexed #{payload["base_path"]}"
end

client.indices.refresh(index: INDEX)
