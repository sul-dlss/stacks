# Creates a okcompter check to see that the Djatoka server is up
class CheckDjatoka < EndpointCheck
  def self.uri_to_check
    Settings.stacks['djatoka'].image.attributes.url + '?rft_id=/&svc_id=info:lanl-repo/svc/ping&url_ver=Z39.88-2004'
  end
end
