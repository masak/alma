use _007::Val;
use _007::Q;

# These multis are used below by infix:<==> and infix:<!=>
multi equal-value($, $) is export { False }
multi equal-value(Val::NoneType, Val::NoneType) { True }
multi equal-value(Val::Bool $l, Val::Bool $r) { $l.value == $r.value }
multi equal-value(Val::Int $l, Val::Int $r) { $l.value == $r.value }
multi equal-value(Val::Str $l, Val::Str $r) { $l.value eq $r.value }
multi equal-value(Val::Array $l, Val::Array $r) {
    if %*equality-seen{$l.WHICH} && %*equality-seen{$r.WHICH} {
        return $l === $r;
    }
    %*equality-seen{$l.WHICH}++;
    %*equality-seen{$r.WHICH}++;

    sub equal-at-index($i) {
        equal-value($l.elements[$i], $r.elements[$i]);
    }

    [&&] $l.elements == $r.elements,
        |(^$l.elements).map(&equal-at-index);
}
multi equal-value(Val::Object $l, Val::Object $r) {
    if %*equality-seen{$l.WHICH} && %*equality-seen{$r.WHICH} {
        return $l === $r;
    }
    %*equality-seen{$l.WHICH}++;
    %*equality-seen{$r.WHICH}++;

    sub equal-at-key(Str $key) {
        equal-value($l.properties{$key}, $r.properties{$key});
    }

    [&&] $l.properties.keys.sort.perl eq $r.properties.keys.sort.perl,
        |($l.properties.keys).map(&equal-at-key);
}
multi equal-value(Val::Type $l, Val::Type $r) {
    $l.type === $r.type
}
multi equal-value(Val::Func $l, Val::Func $r) {
    $l === $r
}
multi equal-value(Q $l, Q $r) {
    sub same-avalue($attr) {
        equal-value($attr.get_value($l), $attr.get_value($r));
    }

    [&&] $l.WHAT === $r.WHAT,
        |$l.attributes.map(&same-avalue);
}
