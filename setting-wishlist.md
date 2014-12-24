## Type conversion

    int(s)                      -- only converts strings looking like /^ '-'? \d+ $/
    str(o)

## String subs

    chars(s)
    substr(s, pos, chars)
    charat(s, pos)
    index(s, substr)            -- returns -1 on substr not found
    split(s, sep)
    trim(s)
    uc(s)
    lc(s)
    ord(s)

## Array subs

    elems(a)
    join(a, sep)
    reversed(a)
    sorted(a)
    map(fn, a)
    grep(fn, a)
