# frozen_string_literal: true

desc 'Test image downloads for large pixel size images'
task test_images: [:environment] do
  require 'faraday'
  druids = %w[bf830pb0546 bb023fw1977 fq505jv7833 hs631zg4177 mj244pd1157 st808xq5141 wq035vh2804]
  conn = Faraday.new ssl: { verify: false }
  druids.each do |druid|
    purl_url = "https://sul-purl-uat.stanford.edu/#{druid}/iiif/manifest"
    resp = conn.get purl_url
    id = JSON.parse(resp.body)['sequences'][0]['canvases'][0]['images'][0]['resource']['@id']
    info_json_url = id.gsub('full/full/0/default.jpg', 'info.json')
    info_resp = conn.get info_json_url
    sizes = JSON.parse(info_resp.body)['sizes']
    body_size = 0
    sizes.each do |size|
      requested_url = id.gsub('full/full', "full/#{size['width']},")
      resp = conn.get requested_url
      status = 'FAIL'
      if resp.body.length >= body_size
        body_size = resp.body.length
        status = 'OK'
      end
      puts "#{size['width']}, #{size['height']}, #{status}, #{resp.body.length}, #{requested_url}"
    end
  end
end
