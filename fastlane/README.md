fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### test_diagnostics

```sh
[bundle exec] fastlane test_diagnostics
```

Run Diagnostics tests

### test_package

```sh
[bundle exec] fastlane test_package
```

Runs tests for a specific package



#### Options

 * **`package_name`**: The name of the package to test

 * **`package_path`**: The path to the package



### test_project

```sh
[bundle exec] fastlane test_project
```

Runs tests for an external project



#### Options

 * **`scheme`**: The project's scheme

 * **`project_path`**: The path to the project

 * **`project_name`**: The name of the project

 * **`parallel_testing`**: Enables parallel testing

 * **`xcargs`**: An optional extra set of arguments to pass to Fastlane Scan

 * **`destination`**: ..

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
