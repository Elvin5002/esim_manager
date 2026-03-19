## 0.0.6
- Fixed some issues Android side

## 0.0.5
- Unified install API to `installEsim(lpa)` across Android and iOS
- Android native install now accepts `lpa` argument and opens system eSIM setup link
- iOS native install now accepts `lpa` argument (with backward-compatible fallbacks)
- Updated example app to use LPA-based install flow with sample LPA string
- Updated README to reflect unified install flow and latest usage

## 0.0.4
- Fixed iOS plugin registration issue (removed invalid dartPluginClass)

## 0.0.3
- Fixed iOS CocoaPods integration by adding missing podspec
- Improved iOS plugin structure and stability
- Updated README with clearer Android & iOS usage examples
- Simplified example application for easier onboarding
- Minor internal cleanup and maintenance improvements

## 0.0.2
- Improved README documentation
- Simplified example application
- Added iOS LPA installation as the recommended flow
- Minor API cleanup and stability improvements

## 0.0.1
- Initial release
- eSIM support check
- Android eSIM install
- iOS LPA install
