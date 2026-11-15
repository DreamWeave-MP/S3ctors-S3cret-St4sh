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

## Tests

```sh
jess package check .
jess package test .
```

- **Golden tests:** two skins and one layout, with the expected tables written by hand from the
  XML.
- **XML reader:** the edge cases the real files contain.
- **Writer:** its layout, and a round trip through it.
- **Checked-in metrics:** the file is exactly what the writer writes for it.
- **Style:** every file passes `@jess/style`.

CI runs both commands in the `Parity tools` job.
