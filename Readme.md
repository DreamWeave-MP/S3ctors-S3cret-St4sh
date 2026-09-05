# S3ctor's S3cret St4sh

Collection of all mods OpenMW Mods developed by S3ctor, Lua and otherwise. From now to the end of time, you'll find everything I make for Morrowind here. That's a promise, Nexus. You can bookmark [this URL](https://dreamweave-mp.github.io/S3ctors-S3cret-St4sh/) to keep up-to-date with all my solo and collaborative releases.

If you just wanna download everything, you can do so from the above link. Follow these links for a description and individual download for each of my mods.

<div id="modMarker"></div>

## Credits

Author: **S3 Nation**  
I made this repository and website, but all my works are built upon the shoulders of giants.  
I'm just a very persistent monkey with a compiler.  

- Special thanks to:

[JohnnyHostile](https://gitlab.com/modding-openmw), owner of [modding-openmw.com](https://modding-openmw.com) for making the template this repo is based on, and welcoming me so graciously as part of the MOMW team.  

[Settyness](https://anfinitinetwork.com/forum/), my newest partner in crime and an excellent shitposter. He's a true inspiration and a really funny dude.  
The rest of the [MOMW](https://modding-openmw.com/about/) and [OpenMW](https://openmw.org/the-team/) team, all of whom I consider to be excellent colleagues and friends.  

[Epoch](https://github.com/EpochWon), who's inspired my own (minor) interest in post-processing, contributed to some components of this repo, and directly inspired the creation of [Morrobroom](https://github.com/magicaldave/Morrobroom/releases/tag/Latest), my [Trenchbroom](https://trenchbroom.github.io) compiler for Morrowind.  

[Ignatious](https://next.nexusmods.com/profile/IgnatiousS/), the creator of Starwind, my mentor, and very close friend.  

The rest of the [Morrowind community](https://discord.gg/pqkUvKfG3q), for whom this is a gift. I genuinely hope you all enjoy what I've put together for you here.  

The [MWSE team](https://mwse.github.io/MWSE/#authors), who are all really cool folks that carried our community for years while OpenMW was waking itself up. You all constantly inspire me to break my own limits, and the engine's.  

AltheaR, whose zealous moderation on Nexus inspired the creation of this repository. None of this would have happened without you.  

## API documentation pages

The Mod Template has an opt-in Cod3x layout for API references, framework guides, and other code-heavy pages. Put docs in a Zola section and select the docs templates in its frontmatter:

```yaml
template: docs/section.html
page_template: docs/page.html

extra:
  api_docs: true
  docs_root: true
  docs_project_name: S3maphore
  docs_short_title: S3maphore Docs
  docs_project_path: '@/s3maphore/index.md'
  docs_repository_url: https://github.com/OWNER/REPOSITORY/tree/main/content/s3maphore
  docs_sidebar_label: Documentation
```

Declare the consumer metadata once on the documentation root. Child pages and sections inherit the selected docs templates through `page_template`; they do not need to repeat the project name, root URL, or search scope. Zola accepts YAML frontmatter as shown above as well as TOML.

API docs get a recursive collapsible project sidebar, a current-page table of contents, breadcrumbs, responsive three-column layout, and copy buttons for fenced code blocks. Guide pages are task-first: lead with the goal and a working example, then explain variations, pitfalls, and related reference. API reference pages are lookup-first: lead with the symbol or item name, signature, and one-sentence summary, then document behavior, parameters, returns, caveats, examples, and related items.
