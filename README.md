# Rails Credentials Conflict

A Rails gem that helps resolve git merge conflicts in encrypted credentials files by decrypting, merging, and re-encrypting them.

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

When you encounter a merge conflict in your credentials file, you have three options:

### 1. Resolve conflicts manually

This command decrypts both versions, opens them in your editor with git conflict markers, and re-encrypts after you've resolved the conflicts:

```bash
# For main credentials
rails credentials:conflict:resolve

# For environment-specific credentials
rails credentials:conflict:resolve -e staging
rails credentials:conflict:resolve -e production
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
6. After you save and close, re-encrypt the resolved content
7. Stage the resolved file with git

### 2. Keep your version

To discard their changes and keep only your version:

```bash
# For main credentials
rails credentials:conflict:yours

# For environment-specific credentials
rails credentials:conflict:yours -e staging
```

### 3. Keep their version

To discard your changes and keep only their version:

```bash
# For main credentials
rails credentials:conflict:theirs

# For environment-specific credentials
rails credentials:conflict:theirs -e production
```

## How it works

The gem uses git's staging area to access both versions of the conflicted file:
- Stage 2 contains "ours" (your version)
- Stage 3 contains "theirs" (their version)

It then:
1. Decrypts both versions using your local key file
2. Performs the requested operation (merge, yours, or theirs)
3. Re-encrypts the result
4. Stages the resolved file

## Requirements

- Ruby >= 3.2.0
- Rails >= 6.0
- Git repository with encrypted credentials
- The appropriate key file must exist locally:
  - `config/master.key` for main credentials
  - `config/credentials/<environment>.key` for environment-specific credentials

## Environment Variable

You can use either `-e` flag or `ENVIRONMENT` environment variable:

```bash
rails credentials:conflict:resolve -e staging
# or
ENVIRONMENT=staging rails credentials:conflict:resolve
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/rails-credentials-conflict.

## License

The gem is available as open source under the terms of the MIT License.
