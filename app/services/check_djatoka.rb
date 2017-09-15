# Creates a okcompter check to see that the Djatoka server is up
class CheckDjatoka
  def self.ok_check
    OkComputer::HttpCheck.new(djatoka_url_to_check)
  end

  def self.djatoka_url_to_check
    Settings.stacks['djatoka'].image.attributes.url + '?rft_id=/&svc_id=info:lanl-repo/svc/ping&url_ver=Z39.88-2004'
  end
end
