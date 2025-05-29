# Split SDK for iOS
![Build Status](https://github.com/splitio/ios-client/actions/workflows/test_ios_ut.yaml/badge.svg?branch=master)
![Build Status](https://github.com/splitio/ios-client/actions/workflows/test_ios_streaming.yaml/badge.svg?branch=master)
![Build Status](https://github.com/splitio/ios-client/actions/workflows/test_ios_integration.yaml/badge.svg?branch=master)

## Overview
This SDK is designed to work with Split, the platform for controlled rollouts, which serves features to your users via a Split feature flag to manage your complete customer experience.

[![Twitter Follow](https://img.shields.io/twitter/follow/splitsoftware.svg?style=social&label=Follow&maxAge=1529000)](https://twitter.com/intent/follow?screen_name=splitsoftware)

## Compatibility
This SDK is compatible with iOS deployment target versions 9.0 and later, and Swift version 4 and later.

## Getting started
Below is a simple example that describes the instantiation and most basic usage of our SDK:
```
// Create a Split config
let config = SplitClientConfig()

// Create a Key to evaluate
let key: Key = Key(matchingKey: "CUSTOMER_ID")

// Setup your Split SDK Key
let sdkKey: String = "YOUR_SDK_KEY"

// Factory builder
let factoryBuilder = DefaultSplitFactoryBuilder()
factoryBuilder.setApiKey(sdkKey).setKey(key).setConfig(config)

// Create a Split factory
let factory = factoryBuilder.build()

// Get a Split Client
let client = factory?.client

// Subscribe to SDK READY event and evaluate your feature flag
client?.on(event: SplitEvent.sdkReady) {
    if let client = client {
        let treatment = client.getTreatment("my_first_feature_flag")
        if treatment == "on" {
            print("I'm ON")
        } else if treatment == "off" {
            print("I'm OFF")
        } else {
            print("CONTROL was returned, there was an error")
        }
    }
}
```

Please refer to [our official docs](https://help.split.io/hc/en-us/articles/360020401491-iOS-SDK) to learn about all the functionality provided by our SDK and the configuration options available for tailoring it to your current application setup.

## Submitting issues

The Split team monitors all issues submitted to this [issue tracker](https://github.com/splitio/ios-client/issues). We encourage you to use this issue tracker to submit any bug reports, feedback, and feature enhancements. We'll do our best to respond in a timely manner.

## Contributing
Please see [Contributors Guide](CONTRIBUTORS-GUIDE.md) to find all you need to submit a Pull Request (PR).

## Development

### Code Formatting

This project uses [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) to maintain consistent code formatting.

#### Installation

Install SwiftFormat using Homebrew:

```bash
brew install swiftformat
```

#### Pre-commit Hook Setup

To automatically format your code before each commit, set up the pre-commit hook:

```bash
# Navigate to the repository root
cd /path/to/ios-client

# Make the pre-commit hook executable
chmod +x scripts/git-hooks/pre-commit

# Create a symbolic link to the pre-commit hook
git config core.hooksPath scripts/git-hooks
```

## License
Licensed under the Apache License, Version 2.0. See: [Apache License](http://www.apache.org/licenses/).

## About Split

Split is the leading Feature Delivery Platform for engineering teams that want to confidently deploy features as fast as they can develop them. Split’s fine-grained management, real-time monitoring, and data-driven experimentation ensure that new features will improve the customer experience without breaking or degrading performance. Companies like Twilio, Salesforce, GoDaddy and WePay trust Split to power their feature delivery.

To learn more about Split, contact hello@split.io, or get started with feature flags for free at https://www.split.io/signup.

Split has built and maintains SDKs for:

* .NET [Github](https://github.com/splitio/dotnet-client) [Docs](https://help.split.io/hc/en-us/articles/360020240172--NET-SDK)
* Android [Github](https://github.com/splitio/android-client) [Docs](https://help.split.io/hc/en-us/articles/360020343291-Android-SDK)
* Angular [Github](https://github.com/splitio/angular-sdk-plugin) [Docs](https://help.split.io/hc/en-us/articles/6495326064397-Angular-utilities)
* GO [Github](https://github.com/splitio/go-client) [Docs](https://help.split.io/hc/en-us/articles/360020093652-Go-SDK)
* iOS [Github](https://github.com/splitio/ios-client) [Docs](https://help.split.io/hc/en-us/articles/360020401491-iOS-SDK)
* Java [Github](https://github.com/splitio/java-client) [Docs](https://help.split.io/hc/en-us/articles/360020405151-Java-SDK)
* JavaScript [Github](https://github.com/splitio/javascript-client) [Docs](https://help.split.io/hc/en-us/articles/360020448791-JavaScript-SDK)
* JavaScript for Browser [Github](https://github.com/splitio/javascript-browser-client) [Docs](https://help.split.io/hc/en-us/articles/360058730852-Browser-SDK)
* Node [Github](https://github.com/splitio/javascript-client) [Docs](https://help.split.io/hc/en-us/articles/360020564931-Node-js-SDK)
* PHP [Github](https://github.com/splitio/php-client) [Docs](https://help.split.io/hc/en-us/articles/360020350372-PHP-SDK)
* Python [Github](https://github.com/splitio/python-client) [Docs](https://help.split.io/hc/en-us/articles/360020359652-Python-SDK)
* React [Github](https://github.com/splitio/react-client) [Docs](https://help.split.io/hc/en-us/articles/360038825091-React-SDK)
* React Native [Github](https://github.com/splitio/react-native-client) [Docs](https://help.split.io/hc/en-us/articles/4406066357901-React-Native-SDK)
* Redux [Github](https://github.com/splitio/redux-client) [Docs](https://help.split.io/hc/en-us/articles/360038851551-Redux-SDK)
* Ruby [Github](https://github.com/splitio/ruby-client) [Docs](https://help.split.io/hc/en-us/articles/360020673251-Ruby-SDK)

For a comprehensive list of open source projects visit our [Github page](https://github.com/splitio?utf8=%E2%9C%93&query=%20only%3Apublic%20).

**Learn more about Split:**

Visit [split.io/product](https://www.split.io/product) for an overview of Split, or visit our documentation at [help.split.io](http://help.split.io) for more detailed information.
