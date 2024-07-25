# frozen_string_literal: true

require "rubocop"

require_relative "rubocop/neeto"
require_relative "rubocop/neeto/version"
require_relative "rubocop/neeto/inject"

RuboCop::Neeto::Inject.defaults!

require_relative "rubocop/cop/neeto_cops"
