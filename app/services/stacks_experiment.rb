class StacksExperiment
  include Scientist::Experiment

  attr_accessor :name

  def initialize(name:)
    @name = name
  end

  def enabled?
    # see "Ramping up experiments" below
    true
  end

  def publish(result)
    # see "Publishing results" below
    puts "Control: "
    result.control.value
    puts "Candidate: "
    result.candidates.first.value
  end
end

# replace `Scientist::Default` as the default implementation
module Scientist::Experiment
  def self.new(name)
    StacksExperiment.new(name: name)
  end
end
