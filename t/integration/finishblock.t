use v6;
use Test;
use nqp;

my $program = slurp("lib/_007/Parser/Actions.pm");
my $compiler = nqp::getcomp('perl6');
my $node = $compiler.compile($program, :target('ast'), :compunit_ok);

sub descend(Mu $node, $indent = 0) {
    my $qast_type = try $node.^name.subst(/'+{QAST::SpecialArg}'/, "");

    given $qast_type {
        when "QAST::Want" {
            if $*in-method {
                descend($node.list[0], $indent + 1);
            }
        }

        when "QAST::Block" {
            if $node.ann('code_object') ~~ Method && (my $methodname = $node.ann('code_object').name) ne "" {
                my $p6typecheckrv = $node.list[1];
                die "Assumption about second child being p6typecheckrv is wrong, bailing out"
                    unless $p6typecheckrv.^name eq "QAST::Op" && $p6typecheckrv.op eq "p6typecheckrv";

                my $stmts = $p6typecheckrv.list[0];
                die "Assumption about first child being QAST::Stmts is wrong, bailing out"
                    unless $stmts.^name eq "QAST::Stmts";

                my $lexotic = $stmts.list[0];
                die "Assumption about first child being lexotic is wrong, bailing out"
                    unless $lexotic.^name eq "QAST::Op" && $lexotic.op eq "lexotic";

                my $p6decontrv = $lexotic.list[0];
                die "Assumption about first child being p6decontrv is wrong, bailing out"
                    unless $p6decontrv.^name eq "QAST::Op" && $p6decontrv.op eq "p6decontrv";

                my $oneMoreStmts = $p6decontrv.list[1];
                die "Assumption about second child being QAST::Stmts is wrong, bailing out"
                    unless $oneMoreStmts.^name eq "QAST::Stmts";

                my $*q-block-new-count = 0;
                my $*self-finishblock-count = 0;
                for $oneMoreStmts.list -> $stmt {
                    my $*in-method = True;
                    descend($stmt, $indent + 1);
                }

                is $*q-block-new-count, $*self-finishblock-count, "finished all Q::Block.new in $methodname";
            }
            else {
                for $node.list -> $child {
                    descend($child, $indent + 1);
                }
            }
        }

        # these all do QAST::Children
        when "QAST::CompUnit" | "QAST::Block" | "QAST::Var" | "QAST::Stmts"
            | "QAST::Op" | "QAST::VM" | "QAST::Stmt" | "QAST::ParamTypeCheck"
            | "QAST::Regex" | "QAST::NodeList" | "QAST::IVal" | "QAST::Want" {

            if $*in-method && $_ eq "QAST::Op" && $node.op eq "callmethod" && $node.name eq "new" {
                my $wval = $node.list[0];
                if $wval.^name eq "QAST::WVal" && $wval.compile_time_value.^name eq "Q::Block" {
                    $*q-block-new-count++;
                }
            }

            if $_ eq "QAST::Op" && $node.op eq "callmethod" && $node.name eq "finish-block" {
                my $var = $node.list[0];
                if $var.^name eq "QAST::Var" && $var.scope eq "lexical" && $var.name eq "self" {
                    $*self-finishblock-count++;
                }
            }

            for $node.list -> $child {
                descend($child, $indent + 1);
            }
        }

        when "QAST::SVal" | "QAST::WVal" | "Str" {
            succeed;
        }

        default {
            die "Unknown node type: ", $node.^name;
        }
    }
}

my $*in-method = False;
descend($node);

done-testing;
