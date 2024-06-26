# frozen_string_literal: true

module Factories
  def self.cocina(id: "druid:nr349ct7889")
    { "externalIdentifier" => id }
  end

  def self.cocina_with_file(id: "druid:nr349ct7889", file_name: 'image.jp2', access: {},
                            file_access: { 'view' => 'world', 'download' => 'world' },
                            mime_type: 'image/jp2')
    cocina(id:).merge(
      'access' => access,
      'structural' => {
        'contains' => [
          {
            'structural' => {
              'contains' => [
                {
                  'filename' => file_name,
                  'hasMessageDigests' => [
                    { 'type' => 'sha1', 'digest' => 'b1a2922356709cc53b85f1b8027982d23b573f80' },
                    { 'type' => 'md5', 'digest' => '02f77c96c40ad3c7c843baa9c7b2ff2c' }
                  ],
                  'hasMimeType' => mime_type,
                  'access' => file_access
                }
              ]
            }
          }
        ]
      }
    )
  end
end
