import std.stdio;
import std.range.primitives;

enum Opcode {
    CONST_INT,
    ADD_INT,
    PRINT,
    PRINT_NL,
    POP_JUMP_IF_FALSE
};

void interpret(int[] input) {
    int i;
    int[] stack;
    while (i < input.length) {
        int next_index = i + 1;

        switch (input[i]) {
            case Opcode.CONST_INT:
                int value = input[i + 1];
                stack ~= value;
                next_index = i + 2;
                break;
            case Opcode.ADD_INT:
                int rhs = stack.back;
                stack.popBack();
                int lhs = stack.back;
                stack.popBack();
                stack ~= lhs + rhs;
                break;
            case Opcode.PRINT:
                int value = stack.back;
                stack.popBack();
                write(value);
                break;
            case Opcode.PRINT_NL:
                writeln();
                break;
            case Opcode.POP_JUMP_IF_FALSE:
                next_index = stack.back == 0 ? input[i + 1] : i + 3;
                break;
            default: // Default case is required.
                break;
        }

        i = next_index;
    }
}

void main()
{
    int[] input = [
        cast(int) Opcode.CONST_INT, 1,
        cast(int) Opcode.CONST_INT, 41,
        cast(int) Opcode.ADD_INT,
        cast(int) Opcode.PRINT,
        cast(int) Opcode.PRINT_NL,
        cast(int) Opcode.CONST_INT, 0,
        cast(int) Opcode.POP_JUMP_IF_FALSE, 11,
        cast(int) Opcode.CONST_INT, 7,
        cast(int) Opcode.PRINT,
        cast(int) Opcode.PRINT_NL
    ];
    interpret(input);
}
