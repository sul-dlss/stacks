##
# Spec helper module to stub the Rights XML for a PURL object.
# It may be a good idea, in the future, to abstract the
# RightsXML fetching into a separate class so that we
# are not stubbing a 3rd party class.
module StubRightsXML
  def stub_rights_xml(xml)
    allow(HTTP).to receive(:get).and_return(
      instance_double(HTTP::Response, body: xml)
    )
  end
end

RSpec.configure do |config|
  config.include StubRightsXML
end
