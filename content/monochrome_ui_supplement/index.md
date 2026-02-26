---
title: Monochrome User Interface Supplement
description: Monochrome UI supplement is, well... a monochrome UI supplement.
date: 2024-08-19

extra:
  install_info:
    data_directories:
      - .
  version: 1.1
---

Monochrome UI supplement is, well... a monochrome UI supplement.

Specifically, this mod replaces some of the built-in textures openmw provides and changes the default text color of Lua widgets. When Monochrome UI first released, there were no Lua widgets and replacing these built-in textures required invasive (and unsafe) modifications to one's game. Now, we can replace both much more easily.

<!-- more -->

This only supports OpenMW 0.48 to 0.50. It is INCOMPATIBLE! With OpenMW 0.51 and later.

## Before And After

<div align="center">
    <img src="../img/monosupplement_before.png" alt="Before Monochrome UI Supplement" />
    <img src="../img/monosupplement_after.png" alt="After Monochrome UI Supplement" />
</div>

{{ install_instructions(describe=true) }}

The skill icons module which was previously part of this mod has now matured into [Beta Icons Restored and Reimagined](../birr/).

Alternatively, here's an example set of momw-configurator customizations for use with total-overhaul:

``` toml
## Total Overhaul
[[Customizations]]
listName = "total-overhaul"

# Monochrome UI Supplement
[[Customizations.insert]]
insert = "/home/sk3shun-8/GitHub/s3stash/monochrome_ui_supplement"
after = "MonochromeUserInterface/monochrome-user-interface"
```


