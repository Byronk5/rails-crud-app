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

### Instance Variables in Controllers & Views

- Instance variables (`@project`) are assigned inside controller actions and automatically made available to the corresponding view
- Each request calls **one action only** — the router decides which based on the HTTP verb and URL
- Local variables (`project`) are scoped to the method and are not passed to the view — always use `@` prefix for view-shared data
- The flow: `GET /projects/1` → router → `ProjectsController#show` → `@project = Project.find(params[:id])` → `show.html.erb`

### Controller Actions & Naming

- Action names like `show`, `index`, `edit` are **conventions**, not rules — the route's `to:` option is what actually maps to the method
- Rails only ever runs one action per request — `@project` defined in `edit` is never touched during a `show` request
- Named route helpers come from the `as:` option in routes: `as: "edit_project"` generates `edit_project_path` and `edit_project_url`
- The name in `as:` can be anything, but convention is `action_resource` (e.g. `edit_project`, `new_project`)

### Partials & `form_with`

- Partials are reusable view snippets — prefixed with `_` in the filename (`_form.html.erb`) but rendered without it: `render "form", project: @project`
- Instance variables are passed into partials as locals: `project: @project` makes `@project` available as `project` inside the partial
- `form_with model: project` is smart — it inspects the object's state:
  - New unsaved record (`Project.new`) → generates `POST /projects` → hits `create`
  - Existing saved record (`Project.find(1)`) → generates `PATCH /projects/1` → hits `update`
- This allows `new.html.erb` and `edit.html.erb` to share the exact same form partial

### Deleting Records

- Browsers only support `GET` and `POST` natively — to send a `DELETE` request from a view, use `button_to` instead of `link_to`
- `button_to` generates a small form under the hood with the correct HTTP method

```erb
<%= button_to "Delete Project", project_path(@project), method: :delete %>
```

- The route must use the `delete` verb:

```ruby
delete "/projects/:id", to: "projects#destroy"
```

- The `destroy` action finds the record, deletes it, then redirects away (usually to the index) since the record no longer exists:

```ruby
def destroy
  @project = Project.find(params[:id])
  @project.destroy
  flash[:notice] = "Project deleted successfully"
  redirect_to projects_path
end
```

- `link_to` can also send a DELETE request by passing `data: { turbo_method: :delete }`, but `button_to` is simpler and more semantically correct for destructive actions

### Flash Messages

- `flash` is a hash that persists data for exactly one redirect — it clears itself after the next request
- Two conventional keys: `flash[:notice]` (success) and `flash[:alert]` (error/warning)
- Set in the controller, read in the view (usually the layout so it appears on every page)

```ruby
# in controller
def create
  @project = Project.new(project_params)
  if @project.save
    flash[:notice] = "Project created successfully"
    redirect_to project_path(@project)
  else
    render :new, status: :unprocessable_entity
  end
end
```

```erb
<!-- in app/views/layouts/application.html.erb -->
<% flash.each do |type, message| %>
  <div class="flash <%= type %>">
    <%= message %>
  </div>
<% end %>
```

- `flash.now` is a variant that only lasts for the **current** request — used with `render` rather than `redirect_to`, since a render doesn't trigger a new request and a normal `flash` would persist one request too many

```ruby
render :new, status: :unprocessable_entity
flash.now[:alert] = "Could not save project"
```

### ERB Common Mistakes

- `<% %>` executes Ruby but outputs nothing — use `<%= %>` to render values to the page
- `% >` with a space before `>` breaks ERB parsing — the closing tag must be `%>` with no space

### State Management in Rails

- Rails is **server-rendered** by default — no persistent frontend state between requests
- State lives in:
  - **The database** — source of truth
  - **The session** — cookie-based store for things like the logged-in user
  - **Flash messages** — one-time messages that survive a single redirect

```ruby
flash[:notice] = "Project created!"
redirect_to projects_path
```

```erb
<%= flash[:notice] %>
```

### JavaScript in Rails

- JS is minimal by default — Rails ships with **Hotwire** (Turbo + Stimulus) from Rails 7+
- **Turbo Drive** — intercepts links/forms, swaps pages without full reload
- **Turbo Frames** — updates specific parts of the page
- **Turbo Streams** — server pushes HTML fragments in real time (live chat, notifications)
- **Stimulus** — lightweight JS controllers attached to existing HTML for behaviour (dropdowns, modals etc.)

| | Hotwire/Rails default | Full JS framework |
|---|---|---|
| JS written | Minimal | A lot |
| Complexity | Low | High |
| Real-time | Supported | Supported |
| SEO | Great (server rendered) | Needs extra work |
| Best for | Content apps, CRUDs, SaaS | Highly interactive UIs |

- Reach for React/Vue only when you need heavy client-side interactivity, offline support, or a shared API for a mobile app

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
