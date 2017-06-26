# Tagging events spike

The results of a spike into using Kibana for tagging analytics

## What we did

First, you'll need a AWS elasticsearch service:

<https://aws.amazon.com/elasticsearch-service/>

Replace the `AWS_SERVICE` constant in `send-to-aws.rb`.

Then generate a CSV (`events.json`) with events from the publishing-api:

<https://github.com/alphagov/publishing-api/pull/944>

Then generate the `users.json` with this incantation in signon:

```ruby
File.write(
  "users.json",
  JSON.dump(
    User.includes(:organisation).map { |u| { user_uid: u.uid, name: u.name, organisation: u.organisation.try(:name) } }
  )
)
```

Then send the data to AWS:

```
ruby send-to-s3.rb
```
