# Rails Credentials Conflict

[![Gem Version](https://badge.fury.io/rb/rails-credentials-conflict.svg)](https://rubygems.org/gems/rails-credentials-conflict)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.txt)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.1.0-red.svg)](https://www.ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-%3E%3D%206.0-red.svg)](https://rubyonrails.org)

Resolve git merge conflicts in Rails encrypted credentials by decrypting, merging, and re-encrypting them. Works with merge, rebase, and cherry-pick.

- [RubyGems](https://rubygems.org/gems/rails-credentials-conflict)
- [Source Code](https://github.com/jwo1f/rails-credentials-conflict)
- [Changelog](CHANGELOG.md)

## Problem

When working with Rails encrypted credentials in a team environment, git merge conflicts in `.yml.enc` files are common. Since these files are encrypted, git cannot automatically merge them, and the conflict markers appear in the encrypted content, making manual resolution impossible.

## Solution

This gem provides rake tasks to:
- Decrypt both versions of conflicted credentials
- Present them in a standard git conflict format for easy resolution
- Re-encrypt the resolved content
- Or simply choose one version over the other

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails-credentials-conflict'
```

And then execute:

```bash
bundle install
```

## Usage

When you encounter a merge conflict in your credentials file, you have four options:

### 1. Resolve conflicts manually

This command decrypts both versions, opens them in your editor with git conflict markers, and re-encrypts after you've resolved the conflicts:

```bash
# For main credentials
rails credentials:conflict:resolve

# For environment-specific credentials
rails credentials:conflict:resolve[staging]
rails credentials:conflict:resolve[production]
```

The command will:
1. Detect the conflict in the encrypted file
2. Decrypt both versions (yours and theirs)
3. Compare them - if identical, auto-merge
4. If different, create a temporary file with git conflict markers:
   ```yaml
   <<<<<<< HEAD (yours)
   api_key: your-key
   =======
   api_key: their-key
   >>>>>>> MERGE_HEAD (theirs)
   ```
5. Open the file in your `$EDITOR` (defaults to vim)
6. After you save and close, validate YAML and re-encrypt the resolved content
7. Stage the resolved file with git

### 2. Keep your version

To discard their changes and keep only your version:

```bash
# For main credentials
rails credentials:conflict:yours

# For environment-specific credentials
rails credentials:conflict:yours[staging]
```

### 3. Keep their version

To discard your changes and keep only their version:

```bash
# For main credentials
rails credentials:conflict:theirs

# For environment-specific credentials
rails credentials:conflict:theirs[production]
```

### 4. Keep base version

To keep the base version (shown in the middle section of 3-way diff):

```bash
# For main credentials
rails credentials:conflict:base

# For environment-specific credentials
rails credentials:conflict:base[staging]
```

## How it works

The gem uses git's staging area to access all versions of the conflicted file:
- Stage 1 contains "base" (merge-base/common ancestor)
- Stage 2 contains "ours" (your version)
- Stage 3 contains "theirs" (their version)

It then:
1. Decrypts the versions using your local key
2. Performs the requested operation (merge, yours, theirs, or base)
3. Validates the resolved YAML
4. Re-encrypts the result
5. Stages the resolved file

Works with merge, rebase, and cherry-pick conflicts.

## Requirements

- Ruby >= 3.1.0
- Rails >= 6.0
- Git repository with encrypted credentials
- The appropriate encryption key must be available via one of:
  - `RAILS_MASTER_KEY` environment variable
  - `config/master.key` for main credentials
  - `config/credentials/<environment>.key` for environment-specific credentials

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jwo1f/rails-credentials-conflict.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
