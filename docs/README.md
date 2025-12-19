# Luma Documentation Site

This directory contains the source files for the Luma documentation website, hosted on GitHub Pages.

## Structure

```text
docs/
├── _config.yml           # Jekyll configuration
├── index.md              # Homepage
├── getting-started.md    # Getting started guide
├── documentation.md      # Complete documentation
├── examples.md          # Examples and use cases
├── API.md               # API reference
├── JINJA2_MIGRATION.md  # Jinja2 migration guide
├── INTEGRATION_GUIDES.md # Framework integrations
└── WHITESPACE.md        # Whitespace control guide
```

## Local Development

### Using Jekyll (Recommended)

```bash
# Install Jekyll
gem install bundler jekyll

# Create Gemfile (first time only)
cd docs
cat > Gemfile << 'EOF'
source "https://rubygems.org"
gem "github-pages", group: :jekyll_plugins
gem "jekyll-relative-links"
gem "jekyll-optional-front-matter"
gem "jekyll-titles-from-headings"
EOF

# Install dependencies
bundle install

# Serve locally
bundle exec jekyll serve
```

Visit `http://localhost:4000/luma/` to preview.

### Using Python (Simple HTTP Server)

```bash
cd docs
python3 -m http.server 8000
```

Visit `http://localhost:8000/` to preview (without Jekyll processing).

## Publishing to GitHub Pages

### Enable GitHub Pages

1. Go to repository Settings
2. Navigate to Pages section
3. Set Source to "Deploy from a branch"
4. Select branch: `main`
5. Set folder: `/docs`
6. Click Save

### Automatic Deployment

GitHub Pages will automatically rebuild and publish when you push changes to the `docs/` directory.

### Custom Domain (Optional)

1. Add a `CNAME` file with your domain:

   ```text
   docs.luma-templates.org
   ```

2. Configure DNS with your domain registrar
3. Enable HTTPS in repository settings

## Theme Customization

Edit `_config.yml` to change the theme:

```yaml
# Built-in GitHub Pages themes:
# - jekyll-theme-cayman (current)
# - jekyll-theme-minimal
# - jekyll-theme-architect
# - jekyll-theme-slate
# - jekyll-theme-tactile
# - jekyll-theme-time-machine
# - jekyll-theme-dinky
# - jekyll-theme-merlot
# - jekyll-theme-hacker
# - jekyll-theme-leap-day
# - jekyll-theme-midnight
# - jekyll-theme-modernist

theme: jekyll-theme-cayman
```

Or use a custom theme from GitHub:

```yaml
remote_theme: owner/repository
```

## Custom Layouts

To customize the layout, create a `_layouts/` directory:

```bash
mkdir -p docs/_layouts
```

Then create `docs/_layouts/default.html` with your custom HTML.

## Adding Pages

Create new markdown files in `docs/` with front matter:

```markdown
---
layout: default
title: My New Page
---

# My New Page

Content goes here...
```

## Navigation

Edit `_config.yml` to add navigation links:

```yaml
nav_links:
  - title: Home
    url: /
  - title: My New Page
    url: /my-new-page
```

## Syntax Highlighting

Code blocks are automatically syntax highlighted:

````markdown
```lua
local luma = require("luma")
local result = luma.render("Hello, $name!", {name = "World"})
```
````

## Resources

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [Jekyll Themes](https://pages.github.com/themes/)
- [Markdown Guide](https://www.markdownguide.org/)
