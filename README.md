# Tagging events spike

The results of a spike into using Kibana for tagging analytics

Run on content store:

```ruby
ContentItem.each do |content_item|
  api_url_method = lambda { |base_path| "http://api.example.com/content/#{base_path}" }

  presented = ContentItemPresenter.new(content_item, api_url_method).as_json

  File.write("/tmp/items/#{content_item["content_id"]}.json", presented.to_json)
end
```

Zip it up:

```
cd /tmp
tar -zcvf content-items.tar.gz items
```

Download the file:

```
scp content-store-1.staging:/tmp/content-items.tar.gz .
```

Send to AWS:

```
ruby send-to-s3.rb
```
