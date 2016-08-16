Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
  h.check :directory, path: File.join(Settings.stacks.storage_root, 'bb')
  h.check :url, get: Settings.purl.url
  h.check :url, get: Settings.stacks.djatoka_url + '?rft_id=/&svc_id=info:lanl-repo/svc/ping&url_ver=Z39.88-2004'

  # if stream_url is down, keep returning status 200 from here for load-balancer check,
  #   but expose failure in html and nagios check
  h.check :non_crucial do |status|
    optional_status = IsItWorking::Status.new('')
    IsItWorking::UrlCheck.new(get: Settings.stream.url).call(optional_status)
    optional_status.messages.each do |x|
      status.ok "#{'FAIL: ' unless x.ok?}#{x.message} (Media viewer uses this for streaming content)"
    end
  end
end
