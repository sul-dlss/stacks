[![Build Status](https://travis-ci.org/sul-dlss/digital_stacks_rails.svg?branch=master)](https://travis-ci.org/sul-dlss/digital_stacks_rails)
[![Coverage Status](https://coveralls.io/repos/sul-dlss/digital_stacks_rails/badge.svg)](https://coveralls.io/r/sul-dlss/digital_stacks_rails)
[![Dependency Status](https://gemnasium.com/sul-dlss/digital_stacks_rails.svg)](https://gemnasium.com/sul-dlss/digital_stacks_rails)
[![Code Climate](https://codeclimate.com/github/sul-dlss/digital_stacks_rails/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/digital_stacks_rails)

# Digital Stacks

The Digital Stacks are the Stanford University Libraries' online systems that house and deliver digital resources to patrons. They work together with discovery systems (such as the catalog, library search engine, finding aids, etc.) to make up the Libraries' digital access services. Digital "stacks" is a convenient metaphor echoing the physical housing of books and other library material. For digital resources it manifests itself to users through the stacks.stanford.edu host name used for access URLs, identifying the virtual location where digital resources can be accessed.

## Requirements

1. Ruby (2.2.1 or greater)
2. Rails (4.2.0 or greater)

## Installation

Clone the repository

    $ git clone git@github.com:sul-dlss/digital_stacks_rails.git

Change directories into the app and install dependencies

    $ bundle install

Start the development server

    $ rails s

## Configuring

Configuration is handled through the [RailsConfig](/railsconfig/config) settings.yml files.

## Testing

The test suite (with RuboCop style inforcement) will be run with the default rake task (also run on travis)

    $ rake

The specs can be run without RuboCop enforcement

    $ rake spec

The RuboCop style enforcement can be run without running the tests

    $ rake rubocop
