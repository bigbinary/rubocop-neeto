# frozen_string_literal: true

module RuboCop
  module Cop
    module Neeto
      # `remove_column` is considered as a dangerous operation. If not used
      # correctly, it could cause irreversible data loss. It is advised to
      # rename the column to `column_name_deprecated_on_yyyy_mm_dd` instead.
      # The renamed column can be safely dropped in a later migration. The cop
      # permits dropping columns that are named in the above format.
      #
      # @example UnsafeColumnDeletion: true (default)
      #   # Enforces the usage of `rename_column` over `remove_column`.
      #
      #   # bad
      #   remove_column :users, :email
      #
      #   # bad
      #   change_table :users do |t|
      #     t.remove :email
      #   end
      #
      #   # good
      #   remove_column :users, :email_deprecated_on_2024_08_09
      #
      #   # good
      #   drop_table :users do |t|
      #     t.remove :email_deprecated_on_2024_08_09
      #   end
      #
      class UnsafeColumnDeletion < Base
        SAFE_COLUMN_NAME_REGEX = /\w+_deprecated_on_\d{4}_\d{2}_\d{2}/
        CURRENT_DATE = DateTime.now.strftime("%Y_%m_%d")

        MSG_REMOVE_COLUMN = "'remove_column' is a dangerous operation. If " \
          "not used correctly, it could cause irreversible data loss. You must perform " \
          "'rename_column :%{table_name}, :%{column_name}, :%{column_name}_deprecated_on_#{CURRENT_DATE}' " \
          "instead. The renamed column can be safely dropped in a future migration."

        MSG_CHANGE_TABLE = "'t.remove' is a dangerous operation. If not used correctly, " \
          "it could cause irreversible data loss. You must perform " \
          "'t.rename :%{column_name}, :%{column_name}_deprecated_on_#{CURRENT_DATE}' " \
          "instead. The renamed column can be safely dropped in a future migration."

        RESTRICT_ON_SEND = %i[remove_column change_table].freeze

        def_node_matcher :unsafe_remove_column?, <<~PATTERN
          (send nil? :remove_column
            ({sym str} $_)
            ({sym str} $_)
            ...)
        PATTERN

        def_node_matcher :unsafe_remove_column_change_table?, <<~PATTERN
          (block (send nil? :change_table _ ...) ...)
        PATTERN

        def_node_matcher :down_method?, <<~PATTERN
          (def :down ...)
        PATTERN

        def on_send(node)
          return unless unsafe_remove_column?(node)

          node.each_ancestor do |parent|
            return if down_method?(parent)
          end

          unsafe_remove_column?(node) do |table_name, column_name|
            message = format(MSG_REMOVE_COLUMN, table_name:, column_name:)
            add_offense(node, message:) unless SAFE_COLUMN_NAME_REGEX.match?(column_name)
          end
        end

        def on_block(node)
          return unless unsafe_remove_column_change_table?(node)

          node.each_ancestor do |parent|
            return if down_method?(parent)
          end

          node.each_descendant(:send) do |send_node|
            next unless send_node.method_name == :remove

            column_name = send_node.arguments.first.value
            message = format(MSG_CHANGE_TABLE, column_name:)
            add_offense(send_node, message:) unless SAFE_COLUMN_NAME_REGEX.match?(column_name)
          end
        end
      end
    end
  end
end
