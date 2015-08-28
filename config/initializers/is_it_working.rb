Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
  h.check :url, get: Settings.purl.url
  h.check :url, get: Settings.stacks.djatoka_url + '?rft_id=/&svc_id=info:lanl-repo/svc/ping&url_ver=Z39.88-2004'

end