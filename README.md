# Pact Ruby Standalone

![Build](https://github.com//pact-ruby-standalone/workflows/Build/badge.svg)
[![Build status](https://ci.appveyor.com/api/projects/status/32ci5o2kikr46kg9?svg=true)](https://ci.appveyor.com/project/MichelBoudreau/pact-ruby-standalone-windows-test)

Creates a standalone pact command line executable using the ruby pact implementation and Travelling Ruby

## Installation

See the [releases](https://github.com/you54f/pact-ruby-standalone/releases) page for installation instructions.

## Usage

Download the appropriate package for your operating system from the [releases](https://github.com/you54f/pact-ruby-standalone/releases) page and unzip it.

    $ cd pact/bin
    $ ./pact-mock-service --help start
    $ ./pact-provider-verifier --help verify

## Supported Platforms

Ruby is not required on the host platform, Ruby 3.1.2 is provided in the distributables

| Version| OS     | Ruby      | Architecture | Supported |
| -------| -------| ------- | ------------ | --------- |
| 2.x| OSX    | 3.1.2     | x86_64       | ✅         |
| 2.x| OSX    | 3.1.2     | aarch64 (arm)| ✅         |
| 2.x| Linux  | 3.1.2   | x86_64       | ✅         |
| 2.x| Linux  | 3.1.2   | aarch64 (arm)| ✅         |
| 2.x| Windows| 3.1.2 | x86_64       | ❌         |
| 2.x| Windows| 3.1.2 | aarch64 (arm)| ❌         |
| 1.x and below| OSX    | 2.4.10       | x86_64       | ✅         |
| 1.x and below| OSX    | 2.4.10    | aarch64 (arm)| ❌         |
| 1.x and below| Linux  | 2.4.10     | x86_64       | ✅         |
| 1.x and below| Linux  | 2.4.10     | aarch64 (arm)| ❌        |
| 1.x and below| Windows| 2.4.10   | x86_64       | ❌         |
| 1.x and below| Windows| 2.4.10   | aarch64 (arm)| ❌         |
| 1.x and below| Windows| 2.4.10   | x86 (32bit)| ✅          |
