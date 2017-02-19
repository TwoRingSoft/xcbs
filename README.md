# xcdanger [![Build Status](https://travis-ci.org/TwoRingSoft/xcdanger.svg?branch=master)] (https://travis-ci.org/TwoRingSoft/xcdanger)

Perform more rigoruous checks on how your Xcode project is changing.

- output fully-resolved build settings for each scheme/configuration combination to .lock files, to track in git

## Why `xcdanger`?

Many ways exist to combine build settings in Xcode, whether through inheritance from Xcode defaults, project/target/configuration level settings, composing xcconfigs using `#include`, or any combination thereof. With such a complex system of settings, making isolated changes without unintended side effects can prove challenging. The test shows a simple example of how a small change (simply changing `SDKROOT` from `iphoneos` to `macosx10.12`) can result in significant changes to many build settings (see `baseline.diff` for the resultant changes).

`xcdanger` will output the full build setting environment for each scheme/configuration combination, and write each of those environments to a lock file. If you check these files into source control and run `xcdanger` regularly, you can see exactly how your build environment will change for seemingly innocuous–or even accidental–changes to your defined build settings.

## What about user paths?

Because many build settings contain paths that only make sense on the machine running the build, paths are replaced with the most granular build setting possible. This keeps the files in .`xcdanger/` from changing for each developer on your team. See [lib/settings-to-unexpand](lib/settings-to-unexpand) to see the build settings whose values are replaced everywhere as they are written to file. _Note: order matters in this list!_

## Installation

```
brew tap tworingsoft/formulae
brew install xcdanger
````

or

```
brew install tworingsoft/xcdanger
```

## Usage

You can run `xcdanger </path/to/.../your.xcodeproj>` any time. The suggested approach is to embed it in a pre-commit hook, as can be seen in the example [pre-commit.sample](scripts/pre-commit.sample).

## Contribution

Please feel free to fork and modify `xcdanger`, pull requests are welcome! Pease read the test [README](test/README.md) to see how to validate your code.

If you find a bug or would like to see a new feature, please open a new issue before writing code.

Please be kind in all your interactions :)
