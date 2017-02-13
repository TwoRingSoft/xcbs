# xcdanger [![Build Status](https://travis-ci.org/TwoRingSoft/xcdanger.svg?branch=master)] (https://travis-ci.org/TwoRingSoft/xcdanger)

Perform more rigoruous checks on how your Xcode project is changing.

- output fully-resolved build settings for each scheme/configuration combination to .lock files, to track in git

## Why `xcdanger`?

Many ways exist to combine build settings in Xcode, whether through inheritance from Xcode defaults, project/target/configuration level settings, composing xcconfigs using `#include`, or any combination thereof. With such a complex system of settings, making isolated changes without unintended side effects can prove challenging. The test shows a simple example of how a small change (simply changing `SDKROOT` from `iphoneos` to `macosx10.12`) can result in significant changes to many build settings (see `baseline.diff` for the resultant changes).

`xcdanger` will output the full build setting environment for each scheme/configuration combination, and write each of those environments to a lock file. If you check these files into source control and run `xcdanger` regularly, you can see exactly how your build environment will change for seemingly innocuous–or even accidental–changes to your defined build settings.

## Installation

```
brew tap tworingsoft/formulae
brew install xcdanger
````

or

```
brew install tworingsoft/xcdanger
```
