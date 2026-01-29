---
title: Beta Icons Restored and Reimagined
description: Replacement icons for skills, spells, and stats inspired by Bethesda's original art style.
date: 2025-07-11

taxonomies:
  tags:
    - Icons
    - User Interface

extra:
  install_info:
    data_directories:
      - .

  version: 0.82
---

Beta Icons Restored and Reimagined provides an alternate glimpse into what might have been. It's based on the [Beta skill icons](https://tcrf.net/Prerelease:The_Elder_Scrolls_III:_Morrowind/Art_and_Textures), which you can find here for reference. However, the beta icons had problems of their own. For one, the rune backgrounds used obfuscated the art a lot for spell icons. Remember, these are displayed at 32x32px for the big spell icons and 16x16px for the small ones. Thus, I took the color palettes of the beta skill icons and extended them to the spell, attribute, and dynamic stat icons. The result is a full suite of character icon replacements (293 in total), best suited for use with [Monochrome UI](https://www.nexusmods.com/morrowind/mods/45174). See below for a preview of all the new icons!

<!-- more -->

{{ install_instructions() }}

Alternatively, here's an example set of momw-configurator customizations for use with total-overhaul:

``` toml
## Total Overhaul
[[Customizations]]
listName = "total-overhaul"

[[Customizations.insert]]
insert = "/home/sk3shun-8/GitHub/s3stash/birr"
after = "BigIcons/07 8X Textured"
```

Some of the icons added by this mod are overwritten by BigIcons, so it should load after that, and anything else that may be modifying icons in your installation.

# Icon Preview

{{ image(src="/img/birrPreview.png", alt="Replacement icons added by BIRR.", style="border-radius: 8px;") }}

{% credits(default=true) %} 
Bethesda Softworks for the original icons  
Glisp for deleting the icons off the CRF wiki page and making me find them  
Zavus for finding these and posting them on MMC in usable format  
{% end %}
