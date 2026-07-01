# frozen_string_literal: true

module Factories
  def self.cocina(id: "druid:nr349ct7889")
    { "externalIdentifier" => id }
  end

  # rubocop:disable Metrics/ParameterLists
  def self.cocina_with_file(id: "druid:bb000cr7262", file_name: 'image.jp2', access: {},
                            md5: '8ff299eda08d7c506273840d52a03bf3',
                            file_access: { 'view' => 'world', 'download' => 'world' },
                            mime_type: 'image/jp2')
    # rubocop:enable Metrics/ParameterLists
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
                    { 'type' => 'md5', 'digest' => md5 }
                  ],
                  'hasMimeType' => mime_type,
                  'size' => 12_345,
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
