# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Neeto::UnsafeColumnDeletion, :config do
  let(:config) { RuboCop::Config.new }

  it "registers an offense when an unsafe column is deleted" do
    snippet = <<~RUBY
      remove_column :neeto_team_members_engine_permissions, :category, :string
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("neeto_team_members_engine_permissions", "category")}
    RUBY
    expect_offense(snippet)

    snippet = <<~RUBY
      remove_column "neeto_themes_engine_themes", "position", :string
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("neeto_themes_engine_themes", "position")}
    RUBY
    expect_offense(snippet)
  end

  it "registers an offense when an unsafe column is deleted using change_table block" do
    snippet = <<~RUBY
      change_table :users do |t|
        t.remove :email, default: "", null: false, type: :string
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("users", "email", true)}
        t.string :last_name, type: :string
      end
    RUBY
    expect_offense(snippet)

    snippet = <<~RUBY
      change_table "users" do |t|
        t.string "last_name"
        t.remove "email", default: "", null: false, type: :string
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("users", "email", true)}
      end
    RUBY
    expect_offense(snippet)
  end

  it "registers multiple offenses when multiple unsafe columns are deleted using change_table block" do
    snippet = <<~RUBY
      change_table :users do |t|
        t.string :last_name
        t.remove :email, default: "", null: false, type: :string
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("users", "email", true)}
        t.datetime :datetime
        t.remove :deactivated_at, type: :datetime
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("users", "deactivated_at", true)}
      end
    RUBY
    expect_offense(snippet)
  end

  it "does not register an offense when a safe column is deleted" do
    snippet = <<~RUBY
      remove_column :users, :email_deprecated_on_2024_08_09
    RUBY
    expect_no_offenses(snippet)

    snippet = <<~RUBY
      remove_column "users", "email_deprecated_on_2024_08_09"
    RUBY
    expect_no_offenses(snippet)
  end

  it "does not trigger an offense when a safe column is deleted with change_table block" do
    snippet = <<~RUBY
      change_table :users do |t|
        t.remove :email_deprecated_on_2024_08_09, default: "", null: false, type: :string
        t.string :last_name, type: :string
      end
    RUBY
    expect_no_offenses(snippet)

    snippet = <<~RUBY
      change_table "users" do |t|
        t.string "last_name"
        t.remove "email_deprecated_on_2024_08_09", default: "", null: false, type: :string
      end
    RUBY
    expect_no_offenses(snippet)
  end

  private

    def offense(table_name, column_name, change_table = false)
      message_template = change_table ?
        RuboCop::Cop::Neeto::UnsafeColumnDeletion::MSG_CHANGE_TABLE
        : RuboCop::Cop::Neeto::UnsafeColumnDeletion::MSG_REMOVE_COLUMN
      message = format(message_template, table_name:, column_name:)
      "Neeto/UnsafeColumnDeletion: #{message}"
    end
end
