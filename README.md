[![Build Status](https://travis-ci.org/sul-dlss/stacks.svg?branch=master)](https://travis-ci.org/sul-dlss/stacks)
[![Coverage Status](https://coveralls.io/repos/sul-dlss/stacks/badge.svg)](https://coveralls.io/r/sul-dlss/stacks)

[![Code Climate](https://codeclimate.com/github/sul-dlss/stacks/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/stacks)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fstacks.svg)](https://badge.fury.io/gh/sul-dlss%2Fstacks)

# Digital Stacks

The Digital Stacks are the Stanford University Libraries' online systems that house and deliver digital resources to patrons. They work together with discovery systems (such as the catalog, library search engine, finding aids, etc.) to make up the Libraries' digital access services. Digital "stacks" is a convenient metaphor echoing the physical housing of books and other library material. For digital resources it manifests itself to users through the stacks.stanford.edu host name used for access URLs, identifying the virtual location where digital resources can be accessed.

## Capabilities

Stacks is responsible for providing 6 endpoints

1. The stacks welcome page https://stacks.stanford.edu/
1. A IIIF endpoint https://stacks.stanford.edu/image/iiif/:id
1. A legacy image service https://stacks.stanford.edu/image/:id/:file_name
(this issues redirects to the IIIF endpoint)
1. A streaming media authentication endpoint that issues and verifies tokens
from the media server
1. File downloads https://stacks.stanford.edu/file/:id/:file_name
1. Web authentication

### IIIF Endpoint
Stacks acts as a proxy to an image server.  The proxy is responsible for ensuring the client has the proper permissions to send the request to the image server.  This work is done by querying the rights metadata from PURL.  Additionally it mutates the info.json response to provide appropriate tile sizes for the users current access level.

Stacks started out as a proxy for the Djatoka server, but in Fall 2017, we added the capability for Stacks to proxy to any IIIF compatible image server. We switched to Canteloupe at that time.  Had RIIIF been our preferred choice at that time, we could have instead pointed Stacks at a server running https://github.com/sul-dlss/image-server/.

Legacy Djatoka support was removed from this codebase in July 2018.
## Requirements

* Ruby (2.2.2+ or greater)

## Installation

Clone the repository

    $ git clone git@github.com:sul-dlss/stacks.git

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
