## Type conversion

    int(s)                      -- only converts strings looking like /^ '-'? \d+ $/
    str(o)
    typeof(o)                   -- returns a string with a typename, "Str", "Int", etc

## Int subs

    abs(n)
    max(a, b)
    min(a, b)
    chr(n)

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
