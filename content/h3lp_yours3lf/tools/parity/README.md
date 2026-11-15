# H3UI parity tools

Tools for H3UI's vanilla parity harness (issue #11): they measure how far an H3UI window is from the
engine's own, in pixels. They are a [jess](https://DreamWeave-MP.github.io/jess) package written in
JSL, and run with jess 0.3.0, the version CI pins in `.github/workflows/h3ui_tests.yml`.

Run every command from this folder. `jess workspace sync --locked` fetches the packages `jess.lock`
pins into `.jess/`, which git ignores.

## extract

Writes `scripts/h3/parity/vanillaMetrics.lua` from an OpenMW checkout's `files/data/mygui`: every
skin in the 17 `.skin.xml` files and every layout in the 61 `.layout` files, as the XML declares
them.

```sh
jess workspace run extract --trusted -- <openmw checkout> ../../scripts/h3/parity/vanillaMetrics.lua \
  <repository URL> '<build>'
```

- **Commit:** the checkout's own `HEAD`, recorded at the top of the file and in `source.commit`.
- **Clean checkout required:** a checkout whose `files/data/mygui` has local changes is refused.
- **Values are declared, not resolved:**
  - attributes keep their XML names, including upstream's capitalised `Align`, which MyGUI ignores;
  - coordinates (`position`, `offset`, `size`, `position_real`) become lists of numbers;
  - properties and user strings stay in file order as `{ key, value }` pairs.
- **Alignment is the reader's job:** MyGUI resolves alignment and skin offsets against the parent's
  size at run time, so whoever reads the file applies that arithmetic.
- **Stable output:** the file is laid out the way Stylua lays it out, so `stylua --check` passes and
  extracting again from the same commit changes nothing.

Re-extract whenever the build that captures move to a new engine commit.

## The manifest

`scripts/h3/parity/manifest.lua` has one entry per reference layout, in #11's order. Each entry
gives:

- its group;
- how the capture fixture opens it (`opens`);
- the game state it needs;
- the widgets every diff masks;
- its status: `not started`, `fixture`, `diffed` or `exact`.

The file's header defines each field.

The manifest test holds it to the metrics module:

- every extracted layout is classified exactly once, so a layout added upstream fails the test
  until it has an entry;
- every mask names a widget of its layout;
- every mode and window is one Lua can open at the engine commit the metrics came from.

## Capturing in game

`examples/h3-parity.omwscripts` is the opt-in capture fixture, loaded like
`examples/h3-fixtures.omwscripts`. Start a run from the console:

```text
luap
I.H3UIParity.run()
I.H3UIParity.run { layouts = { 'messagebox', 'wait_dialog' }, messageSeconds = 15, settleFrames = 10 }
```

The run starts when you close the console and press Insert. It then:

1. **Checks the content list.** It refuses to run with anything loaded besides the three vanilla
   masters, `H3lp Yours3lf.esp`, `h3-parity.omwscripts`, and the `builtin.omwscripts` the engine
   always adds.
2. **Records the conditions** as `S3TRACE` lines: screen and Windows layer size, API revision,
   content list, `fMessageTimePerChar`, and its own timings.
3. **Freezes the scene:** it pauses the world and hides the HUD.
4. **Captures each layout in the manifest** three ways, each twice:
   - **baseline:** the same UI mode with no windows;
   - **vanilla:** the engine's window;
   - **h3:** the H3UI reconstruction over the baseline, where one exists.

   Every capture opens the window afresh, waits `settleFrames` frames, writes a `capture`/`shot`
   trace line, calls `debug.takeScreenshot()`, and closes the window again.
5. **Hands manual layouts to you.** It runs the world, announces the steps, waits for Insert,
   then pauses the world again to capture.

Engine limits it works around, all at the metrics' engine commit:

- **No Lua API places a vanilla window.** The engine decides where each window goes, so the
  differ finds each window from the baseline instead.
- **Lua cannot see the screenshots folder.** The fixture cannot wait for a file. The engine logs
  `<path> has been saved` for each screenshot, and the differ pairs those lines with the
  fixture's `shot` lines in `openmw.log`.
- **Every screenshot puts up its own message box.** It stays for its length times
  `fMessageTimePerChar`, so no capture starts until `messageSeconds` have passed since the last
  one.
- **An interactive message box stays until OK is clicked,** and Lua cannot close it. The fixture
  waits for Insert after each one.
- **Lua cannot tell whether a UI replacer is loaded from a data folder.** Only the content list is
  checked; the rest is a capture condition you set by hand.

## diff

Compares a capture run. It writes `report.md` and one `<layout>.png` difference image per compared
layout:

```sh
jess workspace run diff --trusted -- <openmw.log> <screenshots folder> <output folder>
```

- **Pairing:** each `capture`/`shot` line in the log takes the next screenshot the engine reports,
  as saved or failed. Screenshots are found by file name in the folder given.
- **Per layout, in manifest order:**
  - **not captured:** a capture is missing, or failed to save. The reason is given.
  - **unstable:** the two captures of a variant differ, so the window had not settled.
  - **no window:** the vanilla capture matches its baseline.
  - **vanilla only:** there is no H3UI capture. The window is still recorded.
  - **diffed:** the comparison ran:
    - the window is where vanilla differs from its baseline;
    - the compared rectangle also covers wherever the H3UI capture differs from the baseline;
    - the manifest's masks are placed inside the window by the layout's own geometry, as MyGUI
      aligns it;
    - every differing pixel counts, with no tolerance;
    - the report gives the count and the largest 4-connected differing regions.
- **Difference image:** differing pixels red, masked pixels grey, everything else the vanilla
  capture at a quarter of its brightness.
- **Sizes:** captures of different sizes are an error, never a count.

## Tests

```sh
jess workspace sync --locked
jess package check . --package-path .jess/packages
jess package test . --package-path .jess/packages
```

- **Golden tests:** two skins and one layout, with the expected tables written by hand from the
  XML.
- **XML reader:** the edge cases the real files contain.
- **Writer:** its layout, and a round trip through it.
- **Checked-in metrics:** the file is exactly what the extractor writes for it.
- **Manifest:** the checks above, and each mistake they exist to catch.
- **Differ:**
  - identical captures count zero, a one-pixel change counts one, a change inside a mask counts
    zero, and captures of different sizes are an error;
  - log pairing, every layout outcome, and the regions and difference image;
  - the alignment arithmetic, held to `count_window`'s XML by hand;
  - one run end to end.
- **Style:** every file passes `@jess/style`.

CI runs both commands in the `Parity tools` job.
