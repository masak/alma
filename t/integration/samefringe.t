use v6;
use Test;
use Alma::Test;

# See https://github.com/masak/007/issues/345

{
    my $program = q:to/./;
        func makeNode(left, right) {
            return { left, right };
        }

        func isNode(o) {
            return o ~~ Dict && o.has("left") && o.has("right");
        }

        #   .
        #  / \
        # 1   .
        #    / \
        #   2   3
        my tree1 = makeNode(1, makeNode(2, 3));

        #     .
        #    / \
        #   .   3
        #  / \
        # 1   2
        my tree2 = makeNode(makeNode(1, 2), 3);

        func lazyFlatten(tree) {
            func helper(tree, tailCont) {
                if isNode(tree) {
                    return helper(tree["left"], func() { helper(tree["right"], tailCont) });
                }
                else {
                    return [tree, tailCont];
                }
            }
            return helper(tree, func() { return none; });
        }

        func streamEqual(stream1, stream2) {
            if stream1 == none && stream2 == none {
                return true;
            }
            else if stream1 ~~ Array && stream2 ~~ Array && stream1[0] == stream2[0] {
                return streamEqual(stream1[1](), stream2[1]());
            }
            else {
                return false;
            }
        }

        func sameFringe(tree1, tree2) {
            return streamEqual(lazyFlatten(tree1), lazyFlatten(tree2));
        }

        say(sameFringe(tree1, tree2));
        .

    outputs $program, "true\n", "samefringe reports two trees are the same";
}

done-testing;

