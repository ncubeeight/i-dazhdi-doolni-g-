# i'dazhdi'doolniłígíí

*(GitHub repo slug: `i-dazhdi-doolni-g-` — GitHub repository names only allow
ASCII letters, digits, hyphens, underscores, and periods, so the Diné name
above is carried in this README and the repo description instead.)*

Language support packs for learning — an extensible, **non-LLM** fork of
[Déjà Entendu](https://github.com/ncubeeight/deja-entendu).

## Why this fork exists

Déjà Entendu's mainline app leans on Apple's on-device Foundation Model LLM
for glossing and translation, which means its language support is capped by
whichever languages that model covers. This fork exists to add a second,
independent path: an **importable dictionary-pack architecture** so the app
can look up terms from a static, on-device dictionary — no LLM, no live
network call — starting with a Navajo (Diné) dictionary pack sourced from
the open-source Navajo Translation Project dataset (~12,800 entries).

This is a separate repository rather than a branch of `deja-entendu` for two
reasons:

1. **`deja-entendu` is in Apple App Store review.** Keeping this work in its
   own repo avoids any appearance of the reviewed codebase shifting
   mid-review.
2. **Independence for other developers.** Anyone who wants the
   extensible, non-LLM dictionary-pack approach — for Navajo or any other
   language — can build on this fork without being tied to
   `deja-entendu`'s future Apple Intelligence–specific features and
   constraints (useful for older devices, and for regions where on-device
   LLM use is restricted).

## Relationship to Déjà Entendu

This repository was forked from `deja-entendu`'s `main` branch. From here,
the two projects diverge: `deja-entendu` continues as the Apple
Intelligence–driven mainline; this fork adds the dictionary-pack import
architecture as an additional, LLM-independent lookup path.

## Status

Freshly forked — dictionary-pack architecture (manifest format, importer,
on-device lookup service) is in progress.

## License

Apache License 2.0 (see `LICENSE`).
