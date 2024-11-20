# frozen_string_literal: true

require "byebug"

module RuboCop
  module Cop
    module Neeto
      # `drop_table` is considered as a dangerous operation. If not used
      # correctly, it could cause irreversible data loss. It is advised to
      # rename the table to `table_name_deprecated_on_yyyy_mm_dd` instead. The
      # renamed table can be safely dropped in a later migration. The cop
      # permits dropping tables that are named in the above format.
      #
      # @example UnsafeTableDeletion: true (default)
      #   # Enforces the usage of `rename_table` over `drop_table`.
      #
      #   # bad
      #   drop_table :users
      #
      #   # bad
      #   drop_table :users do |t|
      #     t.string :email, null: false
      #     t.string :first_name, null: false
      #   end
      #
      #   # good
      #   drop_table :users_deprecated_on_2024_08_09
      #
      #   # good
      #   drop_table :users_deprecated_on_2024_08_09 do |t|
      #     t.string :email, null: false
      #     t.string :first_name, null: false
      #   end
      #
      class UnsafeTableDeletion < Base
        # Length of "_deprecated_on_xxxx_xx_xx" = 25, Max permitted length of table: 63
        MAX_TABLE_NAME_LENGTH = 38
        SAFE_TABLE_NAME_REGEX = /\w+_deprecated_on_\d{4}_\d{2}_\d{2}/
        CURRENT_DATE = DateTime.now.strftime("%Y_%m_%d")

        MSG = "'drop_table' is a dangerous operation. If not used correctly, " \
          "it could cause irreversible data loss. You must perform " \
          "'rename_table :%{table_name}, :%{truncated_table_name}_deprecated_on_#{CURRENT_DATE}' " \
          "instead. The renamed table can be safely dropped in a future migration."

        RESTRICT_ON_SEND = %i[drop_table].freeze

        def_node_matcher :unsafe_drop_table?, <<~PATTERN
          (send nil? :drop_table ({sym str} $_) ...)
        PATTERN

        def_node_matcher :down_method?, <<~PATTERN
          (def :down ...)
        PATTERN

        def on_send(node)
          return unless unsafe_drop_table?(node)

          node.each_ancestor do |parent|
            return if down_method?(parent)
          end

          unsafe_drop_table?(node) do |table_name|
            truncated_table_name = table_name.slice(0, MAX_TABLE_NAME_LENGTH)
            message = format(MSG, table_name:, truncated_table_name:)
            add_offense(node, message:) unless SAFE_TABLE_NAME_REGEX.match?(table_name)
          end
        end
      end
    end
  end
end
