# frozen_string_literal: true

# The file rights derived from cocina
class CocinaRights
  def initialize(file_rights)
    @file_rights = file_rights
  end

  def download
    @file_rights['download']
  end

  def view
    @file_rights['view']
  end

  def controlled_digital_lending?
    @file_rights['controlledDigitalLending']
  end

  def location
    @file_rights['location']
  end
end
