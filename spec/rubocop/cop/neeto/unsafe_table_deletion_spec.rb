# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Neeto::UnsafeTableDeletion, :config do
  let(:config) { RuboCop::Config.new }

  it "registers an offense when an unsafe table is dropped" do
    snippet = <<~RUBY
      drop_table :neeto_team_members_engine_permissions
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("neeto_team_members_engine_permissions")}
    RUBY
    expect_offense(snippet)

    snippet = <<~RUBY
      drop_table "neeto_themes_engine_themes"
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("neeto_themes_engine_themes")}
    RUBY
    expect_offense(snippet)
  end

  it "registers an offense when an unsafe table with a block is dropped" do
    snippet = <<~RUBY
      drop_table :users do |t|
      ^^^^^^^^^^^^^^^^^ #{offense("users")}
        t.string :email, null: false
        t.string :first_name
      end
    RUBY
    expect_offense(snippet)

    snippet = <<~RUBY
      drop_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("users")}
        t.string :email, null: false
        t.string :first_name
      end
    RUBY
    expect_offense(snippet)
  end

  it "does not register an offense when a safe table is dropped" do
    snippet = <<~RUBY
      drop_table :users_deprecated_on_2024_08_09
    RUBY
    expect_no_offenses(snippet)

    snippet = <<~RUBY
      drop_table "users_deprecated_on_2024_08_09"
    RUBY
    expect_no_offenses(snippet)
  end

  it "does not register an offense when a safe table with a block is dropped" do
    snippet = <<~RUBY
      drop_table :users_deprecated_on_2024_08_09 do |t|
        t.string :email, null: false
        t.string :first_name
      end
    RUBY
    expect_no_offenses(snippet)

    snippet = <<~RUBY
    drop_table "users_deprecated_on_2024_08_09", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.string :email, null: false
        t.string :first_name
      end
    RUBY
    expect_no_offenses(snippet)
  end

  it "registers an offense with a sliced table name when the table name is too long" do
    table_name = "question_multiple_choice_option_entities"

    snippet = <<~RUBY
    drop_table :#{table_name}
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense(table_name)}
    RUBY

    expect_offense(snippet)
    truncated_table_name = table_name
      .slice(0, RuboCop::Cop::Neeto::UnsafeTableDeletion::MAX_TABLE_NAME_LENGTH)

    expect(offense(table_name)).to include(truncated_table_name)
  end

  private

    def offense(table_name)
      truncated_table_name = table_name.slice(0, RuboCop::Cop::Neeto::UnsafeTableDeletion::MAX_TABLE_NAME_LENGTH)
      message = format(RuboCop::Cop::Neeto::UnsafeTableDeletion::MSG, table_name:, truncated_table_name:)
      "Neeto/UnsafeTableDeletion: #{message}"
    end
end
