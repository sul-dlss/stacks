Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
  h.check :directory, path: File.join(Settings.stacks.storage_root, 'bb')
  h.check :url, get: Settings.purl.url
  h.check :url, get: Settings.stacks.djatoka_url + '?rft_id=/&svc_id=info:lanl-repo/svc/ping&url_ver=Z39.88-2004'
  h.check :url, get: Settings.stream.url
  # need to add LDAP here
end
