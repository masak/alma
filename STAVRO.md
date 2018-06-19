Progress file for the parser codenamed "Stavro".

See [#293](https://github.com/masak/007/issues/293).

## Progress

                        0%      25%     50%     75%     100%
                        |        |       |       |       |
    regex matching      ░

    clone/add/restore   ░

    error messages      ░

    007 language parity ░

## Design notes

* Regex engine in its own .pm file.
* There's the opportunity to copy-on-write with parsers, but maybe not necessary if parsers are lightweight.
* Error messages should always have pathname, line, column, and message. Error should show where the parsefail is.
* In general the error messages should be *excellent*; the golden standard is http://elm-lang.org/blog/compilers-as-assistants
* Most importantly, those error messages are often of the form "found A, but B expected it to be C".
* Also, there are often hints. These have to be added gradually.
* Control is handed back and forth with a `ParseState` object. It's sent into a new parser so it knows where to start, and it's returned back from a parser that's winding down so that the parent parser knows where to continue.
* Provisionally, a `ParseState` contains the source string, the current position, and the category to parse next.
