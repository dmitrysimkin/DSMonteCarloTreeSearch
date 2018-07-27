# DSMonteCarloTreeSearch [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
Monter Carlo Tree Search algorithm swift implementation.

Features: 
- Domain independant
- Search can be limited by time frame, number of iterations or can be stopped manually
- Previous search tree can be reused for next searches
- You can configure the select node policy depending on your needs


## Installation

Framework doesn't contain any external dependencies.

These are currently the supported options:


### [Carthage](https://github.com/Carthage/Carthage)

**Tested with `carthage version`: `0.30.1`**

Add this to `Cartfile`

```
github "dmitrysimkin/DSMonteCarloTreeSearch"
```

```bash
$ carthage update
```

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

**Tested with `pod --version`: `1.5.3`**

```ruby
# Podfile
target 'YOUR_TARGET' do
  use_frameworks!
  pod 'DSMonteCarloTreeSearch'
end

```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```bash
$ pod install
```

### Manually using git submodules

* Add DSMonteCarloTreeSearch as a submodule

```bash
$ git submodule add https://github.com/dmitrysimkin/DSMonteCarloTreeSearch.git
```

* Drag `DSMonteCarloTreeSearch.xcodeproj` into Project Navigator
* Go to `Project > Targets > Build Phases > Link Binary With Libraries`, click `+` and select `DSMonteCarloTreeSearch.framework`

