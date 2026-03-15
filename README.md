# deepl-api-usage

Tiny shell CLI for checking DeepL API usage and quota.

## Features

- `deepl usage`
- `deepl auth set <api-key>`
- `deepl auth show`
- `deepl auth clear`

## Install

Clone the repo and copy the script somewhere on your `PATH`:

```bash
chmod +x bin/deepl
cp bin/deepl /usr/local/bin/deepl
```

Or use it directly from the repo:

```bash
./bin/deepl usage
```

## Auth

You can provide your API key in either of these ways:

```bash
export DEEPL_API_KEY="your-key"
```

or

```bash
deepl auth set "your-key"
```

Saved keys are stored in `~/.config/deepl/config`.

## Usage

```bash
deepl usage
```

Example output:

```text
Used: 62142 / 500000 characters (12.43%)
Remaining: 437858
```

## Reset Timing Note

DeepL's usage endpoint does not expose reset timing for Free API keys. Free and Pro Classic responses return usage counts only. DeepL Pro responses also include billing-period timestamps, so a future version of this CLI could show time-until-reset for Pro accounts.

Reference: https://developers.deepl.com/api-reference/usage-and-quota

## Test

```bash
bash test/test_deepl.sh
```
