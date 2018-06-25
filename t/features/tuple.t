use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        say( (7) );
        say(type( (7) ));
        .

    outputs $program, "7\n<type Int>\n", "just parentheses do not create a tuple";
}

{
    my $program = q:to/./;
        say( (7,) );
        say(type( (7,) ));
        .

    outputs $program, "(7,)\n<type Tuple>\n", "...but a trailing comma in parentheses does";
}

{
    my $program = q:to/./;
        say(7,);
        say(type(7,));
        .

    outputs $program, "7\n<type Int>\n",
        "trailing comma in the argument list is allowed, but does not create a tuple";
}

{
    my $program = q:to/./;
        say( () );
        say(type( () ));
        .

    outputs $program, "()\n<type Tuple>\n", "empty tuple";
}

{
    my $program = q:to/./;
        say( (1, 2, 3) );
        say(type( (1, 2, 3) ));
        say((1, 2, 3).size());
        .

    outputs $program, "(1, 2, 3)\n<type Tuple>\n3\n", "a tuple with several elements";
}

{
    my $program = q:to/./;
        my t = (1, 2, 3);
        say(t[0]);
        say(t[2]);
        .

    outputs $program, "1\n3\n", "you can index into tuples";
}

done-testing;
