# Contributing to Recycle-M

First off, thanks for taking the time to contribute! 🎉

The following is a set of guidelines for contributing to Recycle-M. These are mostly guidelines, not rules. Use your
best judgment, and feel free to propose changes to this document in a pull request.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
    - [Reporting Bugs](#reporting-bugs)
    - [Suggesting Enhancements](#suggesting-enhancements)
    - [Pull Requests](#pull-requests)
- [Style Guides](#style-guides)
    - [Git Commit Messages](#git-commit-messages)
    - [Python Style Guide](#python-style-guide)
    - [Dart/Flutter Style Guide](#dart-flutter-style-guide)

## Code of Conduct

This project and everyone participating in it is governed by the [Recycle-M Code of Conduct](CODE_OF_CONDUCT.md). By
participating, you are expected to uphold this code. Please report unacceptable behavior
to [project maintainer's email].

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report for Recycle-M. Following these guidelines helps maintainers and
the community understand your report, reproduce the behavior, and find related reports.

#### Before Submitting A Bug Report

- **Check the [issues](https://github.com/HardMax71/Recycle-M/issues)** to see if the bug has already been reported.
- **Perform a [cursory search](https://github.com/HardMax71/Recycle-M/issues?q=is%3Aissue)** to see if the bug has been
  mentioned before.

#### How Do I Submit A (Good) Bug Report?

Bugs are tracked as GitHub issues. Create an issue and provide the following information by filling
in [this template](.github/ISSUE_TEMPLATE/bug_report.md):

- **Use a clear and descriptive title** for the issue to identify the problem.
- **Describe the exact steps which reproduce the problem** in as many details as possible.
- **Describe the behavior you observed** after following the steps and point out what exactly is the problem with that
  behavior.
- **Explain which behavior you expected** instead and why.
- **Include screenshots and animated GIFs** which show you following the described steps and clearly demonstrate the
  problem.

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion for Recycle-M, including completely new features
and minor improvements to existing functionality.

#### Before Submitting An Enhancement Suggestion

- **Check the [issues](https://github.com/HardMax71/Recycle-M/issues)** to see if the enhancement has already been
  suggested.
- **Perform a [cursory search](https://github.com/HardMax71/Recycle-M/issues?q=is%3Aissue)** to see if the enhancement
  has been mentioned before.

#### How Do I Submit A (Good) Enhancement Suggestion?

Enhancement suggestions are tracked as GitHub issues. Create an issue on that repository and provide the following
information by filling in [this template](.github/ISSUE_TEMPLATE/feature_request.md):

- **Use a clear and descriptive title** for the issue to identify the suggestion.
- **Provide a step-by-step description of the suggested enhancement** in as much detail as possible.
- **Provide specific examples to demonstrate the steps**.
- **Describe the current behavior** and **explain which behavior you expected instead** and why.

### Pull Requests

The process described here has several goals:

- Maintain Recycle-M's quality
- Fix problems that are important to users
- Engage the community in working toward the best possible Recycle-M
- Enable a sustainable system for maintainers to review contributions

#### Your First Pull Request

1. Fork the repository and clone it locally.
2. Create a branch for your edits.
3. Make your changes.
4. Ensure all tests pass.
5. Commit your changes and push your branch to your fork.
6. Submit a pull request to the `main` branch of the main repository.

#### Pull Request Process

1. Ensure any install or build dependencies are removed before the end of the layer when doing a build.
2. Update the README.md and other documentation with details of changes to the interface, this includes new environment
   variables, exposed ports, useful file locations, and container parameters.
3. Increase the version numbers in any examples files and the README.md to the new version that this Pull Request would
   represent.
4. You may merge the Pull Request in once you have the sign-off of one other developer, or if you do not have permission
   to do that, you may request the second reviewer to merge it for you.

## Style Guides

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line
- Consider starting the commit message with an applicable emoji:
    - :art: `:art:` when improving the format/structure of the code
    - :racehorse: `:racehorse:` when improving performance
    - :memo: `:memo:` when writing docs
    - :bug: `:bug:` when fixing a bug
    - :fire: `:fire:` when removing code or files
    - :lock: `:lock:` when dealing with security
    - :arrow_up: `:arrow_up:` when upgrading dependencies
    - :arrow_down: `:arrow_down:` when downgrading dependencies
    - :shirt: `:shirt:` when removing linter warnings

### Python Style Guide

- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/) as closely as possible.
- Use type annotations to specify function signatures and variable types.
- Document all public classes and methods with docstrings.

### Dart/Flutter Style Guide

- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style) for general Dart code.
- Follow the [Flutter style guide](https://flutter.dev/docs/development/tools/formatting) for Flutter-specific code.
- Use clear and descriptive names for all classes, methods, and variables.
- Write widget tests for all UI components.
- Document all public classes and methods with docstrings.

By adhering to these guidelines, you will help ensure that the Recycle-M project remains maintainable, scalable, and
enjoyable to work on. Thank you for contributing!
