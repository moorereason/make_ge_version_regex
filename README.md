# `make_ge_version_regexp.sh`

A fork of [William Smith's `Match Version Number or Higher.bash`](https://gist.github.com/talkingmoose/2cf20236e665fcd7ec41311d50c89c0e).

## Improvements

- Simplified patterns with 14-25% reduction in character length.
- Unit tests
- CLI options
- No spaces in the script name.

*Improvements compared to May 24, 2020 version of William's script.*

## Usage

```
USAGE:
        ./make_ge_version_regex.sh [OPTIONS] VERSION

OPTIONS:
        -h: show help
        -n: not using jamf
        -s: silent mode
```

Example usage:

```
$ ./make_ge_version_regex.sh -sn 1.0.0

Regex for "1.0.0" or higher (65 characters):

^(\d{2}|[2-9]|1\.\d{2}|1\.[1-9]|1\.0\.\d{2}|1\.0\.[1-9]|1\.0\.0)

```

## Unit Tests

Requires [`bash_unit`](https://github.com/pgrange/bash_unit).

```
bash_unit tests.sh
```

## License

[Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/)
