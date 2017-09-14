module Iiif
  class URI
    def initialize(base_uri:, identifier:, transformation:)
      @base_uri = base_uri
    end

    attr_reader :base_uri
    
    # TODO: do the real id
    def to_s
      base_uri + 'ff%2F139%2Fpd%2F0160%2F67352ccc-d1b0-11e1-89ae-279075081939.jp2/info.json'
    end
  end
end
