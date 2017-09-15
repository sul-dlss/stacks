# @abstract creates okcomputer checks
class EndpointCheck
  def self.ok_check
    OkComputer::HttpCheck.new(uri_to_check)
  end
end
