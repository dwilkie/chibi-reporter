# chibi_reporter

[ ![Codeship Status for dwilkie/chibi-reporter](https://codeship.io/projects/80c93a00-3aee-0132-c57a-12ef9d586401/status)](https://codeship.io/projects/42505)

Handles Reporting for [Chibi](https://github.com/dwilkie/chibi)

## Features

1. Generates monthly xlsx reports and invoices for operators
2. Uploads the reports to S3 and Google Drive
3. Emails the reports to the relevant people

## Development

### Updating the Sample Remote Report

If the [operator config](https://github.com/dwilkie/chibi/blob/master/config/custom_operators.yaml) in [Chibi](https://github.com/dwilkie/chibi) changes, you should update the [sample remote report](https://github.com/dwilkie/chibi-reporter/blob/master/spec/support/sample_remote_report.yaml). To do this, open up [report spec in Chibi](https://github.com/dwilkie/chibi/blob/master/spec/models/report_spec.rb#L207) and insert a line to output the `asserted_report` as yaml. e.g.

```ruby
it "should generate a report" do
  asserted_report
  File.open("sample_remote_report.yaml", 'w') { |file| file.write(asserted_report.to_yaml) }
  # Rest of spec
end
```

This will dump a sample report to yaml. Then replace the [sample remote report](https://github.com/dwilkie/chibi-reporter/blob/master/spec/support/sample_remote_report.yaml) with the newly generated report.

### Inspecting the output of a report

In the [spec helpers](https://github.com/dwilkie/chibi-reporter/blob/master/spec/support/chibi_reporter_spec_helpers.rb#L345) you can insert a line to output the generated report. e.g.

```ruby
describe "#generate!" do
  it "should create a report and return a string IO" do
    result = subject.generate!
    File.open("sample_output.xlsx", 'w') { |file| file.write(result.read) }
    # Rest of spec
  end
end
```

You should then be able to open `sample_output.xlsx`

## Usage

chibi-reporter is deployed to Heroku. It is scheduled to generate a new remote report for the previous month at 8:00am ICT every day. This report should be the same everytime it runs in a given month. At 9:00am ICT it will then try to generate operator reports if there are none for the current month. This means that operator reports for the previous month should be delivered around 9:00am ICT on the first day of every new month.

### Generating a remote report

To generate a new remote report on the server for the *previous month* run:

```shell
heroku run:detached bundle exec rake chibi:reporter:remote_report:generate
```

To generate a new remote report for *any given month* e.g. October 2013 run:

```shell
heroku run:detached CHIBI_REPORTER_REMOTE_REPORT_MONTH=10 CHIBI_REPORTER_REMOTE_REPORT_YEAR=2013 bundle exec rake chibi:reporter:remote_report:generate
```

For example if this command is run on 1st January 2014, then it will generate a new remote report for December 2013. It will also clear the existing report from November 2013.

### Processing the remote report

To process the remote report run:

```shell
heroku run:detached bundle exec rake chibi:reporter:report_generator:run
```

This will generate xlsx reports for the the operators, upload them and email them to the relevant people based for the data from the remote report created above. This will happen *only* if the reports have *never* been generated for that particular month. To force reports to be re-generated run:

```shell
heroku run:detached CHIBI_REPORTER_REPORT_FORCE_GENERATE=1 bundle exec rake chibi:reporter:report_generator:run
```

Note that this will *not* resend any emails.

## Configuration

Configuration is done with environment variables. Refer to [.env](https://github.com/dwilkie/chibi-reporter/blob/master/.env) for configuration options

### Updating the Google Refresh Token

After a long period of time the Google Refresh Token will expire. Follow the instructions below to update the refresh token:

```ruby
require 'googleauth'
require 'googleauth/stores/file_token_store'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

scope = 'https://www.googleapis.com/auth/drive'
client_id = Google::Auth::ClientId.from_file(ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"])
token_store = Google::Auth::Stores::FileTokenStore.new
authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)

url = authorizer.get_authorization_url(base_url: OOB_URI )

# open url in browser and copy authorization code

credentials = authorizer.get_credentials_from_code(code: code, base_url: OOB_URI)
```
