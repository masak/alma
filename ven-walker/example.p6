func tag(x) {
  return func show(n) {
    say("hello: " ~ x ~ "!");
  }
}

say("[ simple test ]");
my node = quasi { say(""); };
walk(node, [
  #[Q, tag("Q")],
  #[Q.Expr, tag("expr")],
  [Q.Term, tag("term")],
  [Q.Literal, tag("Literal")],
  [Q.Literal.Str, tag("str")],
]);

say("[ macro test ]");
macro replaceStrLiteral(ast) {
  return walk(ast, [
    [Q.Literal.Str, func (node) {
      return quasi { "hi there" };
    }],
  ]);
}; 
replaceStrLiteral(
  say("Argument to the macro...")
);
