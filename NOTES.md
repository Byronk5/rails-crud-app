# Study Notes

## Ruby / Ruby on Rails

### Active Record
- Rails' ORM layer — maps database tables to Ruby classes, rows to objects
- Each model inherits from `ApplicationRecord` and maps to a pluralized table (`Project` → `projects`)
- Common query methods: `all`, `find`, `where`, `first`, `order`
- Supports associations: `has_many`, `belongs_to`
- Supports validations and callbacks (`before_save`, etc.)
- Schema changes are managed via migrations

### Databases
- Active Record works with any relational database (SQLite, PostgreSQL) — only `database.yml` and the adapter gem change, model/query code stays the same
- Non-relational databases (e.g. MongoDB) require a different ORM — **Mongoid** — and a different mental model (documents/collections instead of tables/rows)
- PostgreSQL is the standard production choice; SQLite is fine for learning

### ERB Templates
- `<% %>` — executes Ruby, outputs nothing
- `<%= %>` — executes Ruby and outputs the result
- `content_for :title, "..."` — sets the page title, injected into the layout via `yield :title`
- `render "form", todo: @todo` — renders a partial (`_form.html.erb`), passing instance variables as locals
- `link_to "text", path_helper` — generates an `<a>` tag using Rails route helpers

### Rails Router
- `get "/projects/:id", to: "projects#show", as: "project"`
  - `:id` is a dynamic segment, captured as `params[:id]` in the controller
  - `to:` maps to `ProjectsController#show`
  - `as:` generates named route helpers: `project_path(@project)` and `project_url(@project)`
- `resources :projects` auto-generates this route and 6 others following REST conventions

### Rails CLI — Generate

| Command | What it creates |
|---|---|
| `bin/rails generate model Post` | Model, migration, test files |
| `bin/rails generate controller Posts` | Controller, views, helper, test files |
| `bin/rails generate scaffold Post title:string body:text` | Full CRUD — model, controller, views, migration |
| `bin/rails generate migration AddTitleToPosts title:string` | A standalone migration file |
| `bin/rails destroy model Post` | Undoes a generate command |

- Column types: `string`, `text`, `integer`, `boolean`, `decimal`, `datetime`, `references`
- `references` adds a foreign key: `bin/rails generate model Task project:references` adds `project_id`

### Rails CLI — Database

| Command | What it does |
|---|---|
| `bin/rails db:create` | Creates the database |
| `bin/rails db:migrate` | Runs pending migrations |
| `bin/rails db:rollback` | Reverts the last migration |
| `bin/rails db:rollback STEP=3` | Reverts the last 3 migrations |
| `bin/rails db:reset` | Drops, recreates, and migrates the database |
| `bin/rails db:seed` | Runs `db/seeds.rb` to populate data |
| `bin/rails db:schema:load` | Rebuilds the database from `schema.rb` (faster than re-running all migrations) |

### Migrations

- Live in `db/migrate/` — each file is timestamped and run once
- `change` method handles both `migrate` and `rollback` automatically for common operations
- Common helpers inside a migration:

```ruby
create_table :projects do |t|
  t.string :name
  t.text :description
  t.timestamps  # adds created_at and updated_at
end

add_column :projects, :status, :string
remove_column :projects, :status
add_index :projects, :name
```

- `db/schema.rb` is the authoritative snapshot of the current database structure — never edit it manually

---

## Neovim

### Ruby & Rails LSP
- Recommended LSP: **ruby-lsp** (by Shopify) — actively developed, better Rails awareness
- Alternative: **solargraph** — avoid running both simultaneously as they conflict
- Install via Mason: `:MasonInstall ruby-lsp`
- Also requires the gem: `gem install ruby-lsp`

### Ruby Formatter
- **RuboCop** — handles linting and formatting, Rails-aware via `rubocop-rails`
- ruby-lsp integrates RuboCop internally, so it surfaces offenses through the LSP directly
- Install via Mason: `:MasonInstall rubocop`

### ERB Formatter
- **htmlbeautifier** — standard formatter for `.erb` files
- Install via Mason: `:MasonInstall htmlbeautifier` and `gem install htmlbeautifier`
- Added to `none-ls.lua` as `null_ls.builtins.formatting.htmlbeautifier`
- Targets the `eruby` filetype automatically

### Snippet Completion Fix
- Typing `<h1` and confirming a snippet was leaving a leading `<` (`<<h1></h1>`)
- Cause: `<` is not part of nvim-cmp's default keyword pattern, so only `h1` was replaced
- Fix: added a filetype-specific keyword pattern in `completions.lua` for `html` and `eruby`:
  ```lua
  cmp.setup.filetype({ "html", "eruby" }, {
    keyword_pattern = [[\%(<\?\h\w*\)]],
  })
  ```
- This covers all HTML tags, not just `<h1`
