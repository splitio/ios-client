# Contributing to the Split iOS SDK

Split SDK is an open source project and we welcome feedback and contribution. The information below describes how to build the project with your changes, run the tests, and send the Pull Request(PR).

## Development

### Development process

1. Fork the repository and create a topic branch from `development` branch. Please use a descriptive name for your branch.
2. While developing, use descriptive messages in your commits. Avoid short or meaningless sentences like "fix bug".
3. Make sure to add tests for both positive and negative cases.
4. Run the linter script of the project and fix any issues you find.
5. Run the build and make sure it runs with no errors.
6. Run all tests and make sure there are no failures.
7. `git push` your changes to GitHub within your topic branch.
8. Open a Pull Request(PR) from your forked repo and into the `development` branch of the original repository.
9. When creating your PR, please fill out all the fields of the PR template, as applicable, for the project.
10. Check for conflicts once the pull request is created to make sure your PR can be merged cleanly into `development`.
11. Keep an eye out for any feedback or comments from Split's SDK team.

### Building the SDK

```
// Create a Split config
let config = SplitClientConfig()

// Create a Key to evaluate
let key: Key = Key(matchingKey: "CUSTOMER_ID")

// Setup your Split Api Key
let apiKey: String = "API_KEY"

// Factory builder
let factoryBuilder = DefaultSplitFactoryBuilder()
factoryBuilder.setApiKey(apiKey).setKey(key).setConfig(config)

// Create a Split factory
let factory = factoryBuilder.build()

// Get a Split Client
let client = factory?.client

// Subscribe to SDK READY event and evaluate your Split
client?.on(event: SplitEvent.sdkReady) {
    if let client = client {
        let treatment = client.getTreatment("my_first_split")
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

### Running tests

To run tests open Product menu on Xcode and select Test option.

### Linting and other useful checks

Swiftlint is setup to run after the build process. To check if any issue ocurrs open issue navigator in Xcode

# Contact

If you have any other questions or need to contact us directly in a private manner send us a note at sdks@split.io
