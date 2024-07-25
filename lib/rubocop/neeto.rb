# frozen_string_literal: true

require "pathname"
require "yaml"
require_relative "neeto/version"

module RuboCop
  module Neeto
    class Error < StandardError; end
    # Your code goes here...
    PROJECT_ROOT = Pathname.new(__dir__).parent.parent.expand_path.freeze
    CONFIG_DEFAULT = PROJECT_ROOT.join("config", "default.yml").freeze
    CONFIG = YAML.safe_load(CONFIG_DEFAULT.read).freeze

    private_constant(:CONFIG_DEFAULT, :PROJECT_ROOT)
  end
end
