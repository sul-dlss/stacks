Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
  h.check :directory, path: File.join(Settings.stacks.storage_root, 'bb')
  h.check :url, get: Settings.purl.url

  h.check :non_crucial do |status|
    djatoka_url_to_check = Settings.stacks.djatoka_url + '?rft_id=/&svc_id=info:lanl-repo/svc/ping&url_ver=Z39.88-2004'
    non_crucial_url_check(djatoka_url_to_check, status, 'For image content in image viewer')
  end
end

# even if url doesn't return 2xx or 304, return status 200 here
#  (for load-balancer check) but expose failure in message text (for nagios check and humans)
def non_crucial_url_check(url, return_status, info)
  non_crucial_status = IsItWorking::Status.new('')
  IsItWorking::UrlCheck.new(get: url).call(non_crucial_status)
  non_crucial_status.messages.each do |x|
    return_status.ok "#{'FAIL: ' unless x.ok?}#{x.message} (#{info})"
  end
end
