[![CI](https://github.com/sul-dlss/stacks/actions/workflows/ruby.yml/badge.svg)](https://github.com/sul-dlss/stacks/actions/workflows/ruby.yml)
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

## Developing

For local development, the app will skip checks for the presence of image files and proxy the request to production image servers. You'll need to be on the Stanford VPN for this to work.

A IIIF image request (#2 under "Capabilities" above) to production might look like: `https://stacks.stanford.edu/image/iiif/qj283wt8591%2FRT0073990001/info.json`

In local development, this will become: `http://localhost:3000/image/iiif/qj283wt8591%2FRT0073990001/info.json`.

## Deploying with Kamal

Kamal deploys the container image from GHCR to the production hosts listed in `config/deploy.yml`.
Copy `.kamal/secrets.example` to `.kamal/secrets`, set each referenced environment variable, and ensure
your SSH agent can access the `stacks` account. Then run:

    $ bin/kamal setup
    $ bin/kamal deploy

## Configuring

Configuration is handled through the [RailsConfig](/railsconfig/config) settings.yml files.

### Offloading file downloads to NGINX

The optional download proxy keeps `/file/...` and `/v2/file/...` URLs on the same
public HTTP port. Rails authorizes the request, resolves the version's storage
key, and queues download tracking. It then returns `X-Accel-Redirect` to an
NGINX `internal` location. NGINX streams the object through
[nginx-s3-gateway](https://github.com/nginx/nginx-s3-gateway), freeing Rails before
the transfer starts. Login, OPTIONS, IIIF, and other application requests continue
to use Rails. Dynamically generated `/object/...` ZIPs still stream through Rails.

Run the container setup with Docker Compose 2.24 or newer:

```sh
docker compose -f compose.yaml -f compose.downloads.yaml up --build
```

The application remains available at `http://localhost:3001`. Only the front
NGINX publishes the application port; Rails and the S3 gateway are private Docker
services. The local S3 backend is RustFS, and its bucket must contain objects
matching the Cocina metadata, just as for direct Rails downloads.

The overlay enables `SETTINGS__FEATURES__DOWNLOAD_PROXY=true`. Without it, the
application retains its direct streaming behavior, including `bin/rails server`.
Never enable that setting on a public Rails listener without the front proxy:
clients would receive an empty response instead of the file.

For Weka, configure both Rails and the gateway for the same bucket and endpoint:

```sh
export S3_ENDPOINT=https://sul-weka-s3.stanford.edu
export S3_SERVER=sul-weka-s3.stanford.edu
export S3_SERVER_PORT=443
export S3_SERVER_PROTO=https
export S3_BUCKET_NAME=your-bucket
# Supply SETTINGS__S3__ACCESS_KEY_ID and SETTINGS__S3__SECRET_ACCESS_KEY
# through your deployment's secret management.
docker compose -f compose.yaml -f compose.downloads.yaml up --build
```

The gateway uses path-style addressing, Signature V4, and certificate verification
for HTTPS origins. Its source revision is pinned in `compose.downloads.yaml`.
Our gateway template uses the upstream credential/signing libraries but disables
object caching, directory listing, index handling, and range slicing. Rails
validates ranges (retaining the existing single-range behavior) and evaluates
`If-Range` against its own validators; S3 supplies the bytes and final length.
The front proxy preserves Rails' MIME type, disposition, cache policy, validators,
and CORS headers. Every download still passes through Rails authorization.

### Staging with host Apache/Passenger

Use `compose.stage-downloads.yaml` **by itself**, not as an overlay on the local
Compose files. It runs only the proxies; Capistrano continues managing Rails.
Copy it, `s3.stage.env.example`, and `config/nginx/` (preserving that directory
structure) into a stable directory such as `/opt/app/stacks/download-proxy`.
Copy `s3.stage.env.example` to `s3.stage.env`, fill in stage's bucket and credentials,
and run `chmod 600 s3.stage.env`. That file is ignored by Git.

The staging topology is:

```text
Public HTTPS :443 -> NGINX -> Apache/Passenger 127.0.0.1:8443
                          -> internal download -> S3 gateway 127.0.0.1:8082 -> Weka
```

Before starting the front proxy, update the host's Puppet configuration:

* Change Apache's `Listen 443` and `<VirtualHost *:443>` to
  `Listen 127.0.0.1:8443` and `<VirtualHost 127.0.0.1:8443>`.
* Preserve Passenger, Shibboleth, directory/location rules, TLS certificates,
  and encoded-slash handling. Keep the public canonical URL on HTTPS port 443;
  verify Shibboleth login/callback URLs do not acquire the private port.
* Keep Apache's port-80 redirect and certificate-renewal handling.

The new `config/nginx/downloads-tls.conf.template` terminates public TLS and
verifies Apache's upstream certificate against `sul-stacks-stage.stanford.edu`.
The Compose file mounts `/etc/letsencrypt` read-only, including `live/` symlinks
and their `archive/` targets. The front container uses Linux host networking.
It replaces client-supplied forwarding headers with the actual peer IP and the
public HTTPS scheme/port. If a load balancer sits in front, configure NGINX's
real-IP handling for that trusted balancer before using location-based rights.

From the stable deployment directory, with the Rails feature still disabled:

```sh
docker compose -f compose.stage-downloads.yaml build s3_gateway
docker compose -f compose.stage-downloads.yaml up -d s3_gateway
curl --fail http://127.0.0.1:8082/health
docker compose -f compose.stage-downloads.yaml run --rm --no-deps downloads nginx -t
# After Apache has released public port 443 and serves its private listener:
docker compose -f compose.stage-downloads.yaml up -d downloads
curl --resolve sul-stacks-stage.stanford.edu:443:127.0.0.1 \
  --head https://sul-stacks-stage.stanford.edu/
```

If the earlier trial Compose deployment is still running, stop its proxy services
before starting this one; both would otherwise claim port 8082. A gateway health
response only checks NGINX: also test a known object key to verify Weka access.
Validate login, real client IP, public and restricted files before enabling
`features.download_proxy` in staging's managed Rails settings and restarting Rails.
Then check ranges, HEAD, and that direct `/_private_s3/` requests return 404.

Add the following to certificate renewal's successful deploy hook (using the
actual stable deployment path), so NGINX loads the renewed certificate:

```sh
docker compose -f /opt/app/stacks/download-proxy/compose.stage-downloads.yaml \
  exec -T downloads nginx -s reload
```

Recreate the affected container after template changes to rerender its configuration.
Ensure Docker starts at boot. Restrict gateway credentials to bucket read access.
To roll back the handoff, disable the Rails feature flag and restart Rails;
the front proxy will forward Rails' streamed responses normally. These files do
not change Puppet, deploy to stage, or migrate Apache into a container.

## Testing

You will want to start up the Docker container which uses RustFS to replace Amazon S3 storage:

    $ docker compose up -d

The test suite (with RuboCop style inforcement) will be run with the default rake task (also run in CI)

    $ rake

The specs can be run without RuboCop enforcement

    $ rake spec

The RuboCop style enforcement can be run without running the tests

    $ rake rubocop
