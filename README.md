# chibi_reporter

Handles Reporting for Chibi

## Features

1. Generates monthly xlsx reports and invoices for operators
2. Uploads the reports to S3 and Google Drive
3. Emails the reports to the relevant people

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
