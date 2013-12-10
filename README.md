# chibi_reporter

Handles Reporting for Chibi

## Features

1. Generates monthly xlsx reports and invoices for operators
2. Uploads the reports to S3 and Google Drive
3. Emails the reports to the relevant people

## Usage

### Generating a remote report

To generate a new remote report on the server for the *previous month* run:

```shell
bundle exec rake chibi:reporter:remote_report:generate
```

For example if this command is run on 1st January 2014, then it will generate a new remote report for December 2013. It will also clear the existing report from November 2013.

### Processing the remote report

To process the remote report run:

```shell
bundle exec rake chibi:reporter:report_generator:run
```

This will generate xlsx reports for the the operators, upload them and email them to the relevant people.

## Configuration

Configuration is done with environment variables. Refer to [.env](https://github.com/dwilkie/chibi-reporter/blob/master/.env) for configuration options
