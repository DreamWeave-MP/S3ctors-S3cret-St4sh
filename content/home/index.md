---
title: My Example Mod
description: This is the description being shown on the page
date: 2025-12-27

# All taxonomies are optional,
# but help make your site more navigable if used.
# You can use any number of taxonomies you want, 
# For sorting by author, date, engine, etc etc.
taxonomies:
  tags:
    - Some
    - Tag
    - Name

extra:
  # Override the `title` for dev builds on a per-page basis. Optional.
  #dev_title: "This is what shows up when you hover over the Dev download button"

  # Use this to hide the download/version bar entirely on some pages
  hide_download_bar: false

  # If used, informs the install instructions widget how to install this mod.
  # If left unfilled, only one data directory with a slugified version of the page title is used for install instructions.
  # Content Files and fallback entries are optional.
  # Missing config= and settings.cfg configurations.
  install_info:
    data_directories:
      - 00 Main Mod
      - 01 Some Option
      - 01 Some Other Option
    content_files:
      - Some.esp
      - SomeOther.esp
      - An.omwaddon
    fallback_entries:
      SomeColor: 420-42-69
      SomeOtherColor: 320,220,369
    config:
      - .

  # Use this if you're publishing an application on this page and not just a mod
  # This will give you more appropriate download buttons for your platform.
  # Defauts to false, since we're only hosting mods in most cases.
  is_binary: false

  # This is used to generate mod manager download links
  # as well as other metadata about this specific mod.
  # Defaults to `morrowind`, probably never actually needs filled out.
  game: morrowind

  # If your mod is also hosted on NexusMods, put the id here to link
  # Back to the nexus page. Optonal.
  nexus_id: 57511

  # Use this field if you're hosting from another castle.
  # Both `owner` and `repo` are required, but `giscus` is not.
  offsite_host:
    owner: DreamWeave-MP
    repo: S3LightFixes
    giscus:
      repo_id: R_kgDONYe6SQ
      category_id: DIC_kwDONYe6Sc4C0Jkq

  # If true, only show the frontmatter description on index pages
  # If you want to hide the summary text completely
  # set this to true, and leave the description unset.
  # Otherwise, make sure to add a 
  # <!-- more -->
  # Marker to your pages to indicate the end of the summary.
  show_only_description: false

  # Override the `title` for stable builds on a per-page basis
  stable_title: "This is what shows up when you hover over the Stable download button"

  # Not everything needs a TOC. If not, uncomment this
  #use_toc: false

  # Curently-available version of your mod/app. Required!
  version: 4.2.0
---

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc eu feugiat sapien.

<!-- more -->

{{ install_instructions(describe=true) }}

[WTFJS](https://wtfjs.com)

```javascript
>>> [1, 2, 3, 15, 30, 7, 5, 45, 60].sort()
[1, 15, 2, 3, 30, 45, 5, 60, 7]
```

# Try Clicking Me!

## Headings link to and from the table of contents.

# Contents Are

## Generated Up To

### Heading 3

{% credits(default=true) %}
The above default text can be disabled, or replaced by editing default_credits in your config.toml
Credits are automatically underlined,
Per-line, by 40% of their width.
Except the last one.
{% end %}
