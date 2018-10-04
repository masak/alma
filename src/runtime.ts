enum Type {
    Int,
    Str,
}

export function value<T>(v: T): RuntimeValue<T> {
    if (typeof v == "number") {
        return { type: Type.Int, value: v };
    }
    else if (typeof v == "string") {
        return { type: Type.Str, value: v };
    }
    throw new Error("Unable to handle type " + typeof v);
}

enum OpCode {
    Load,
    Print,
}

interface RegisterRef {
    _tag: "register";
    index: number;
}

interface ConstantRef {
    _tag: "constant";
    index: number;
}

interface Instruction {
    _tag: "instruction";
    opcode: OpCode;
    operands: any[];
}

export namespace op {
    export function Load(r: RegisterRef, c: ConstantRef): Instruction {
        return { _tag: "instruction", opcode: OpCode.Load, operands: [r, c] };
    }

    export function Print(r: RegisterRef): Instruction {
        return { _tag: "instruction", opcode: OpCode.Print, operands: [r] };
    }
}

interface RuntimeValue<T> {
    type: Type;
    value: T;
}

export function reg(index: number): RegisterRef {
    return { _tag: "register", index };
}

export function cst(index: number): ConstantRef {
    return { _tag: "constant", index };
}

interface Output {
    print(value: any): void;
}

class MockOutput implements Output {
    private contents = "";

    print(value: any) {
        this.contents += value;
    }

    toString() {
        return this.contents;
    }
}

class StandardOutput implements Output {
    print(value: any) {
        console.log(value);
    }
}

class Runtime {
    private output: Output;

    constructor(
        private constants: RuntimeValue<any>[],
        private instructions: Instruction[],
        { output = new StandardOutput() }: { output: Output }
    ) {
        this.output = output;
    }

    run(): void {
        let registers: { [index: number]: RuntimeValue<any> } = {};
        for (let instruction of this.instructions) {
            switch (instruction.opcode) {
            case OpCode.Load:
                registers[instruction.operands[0].index] = this.constants[instruction.operands[1].index];
                break;

            case OpCode.Print:
                this.output.print(registers[instruction.operands[0].index].value);
                break;
            }
        }
    }
}

export function programWithOutput(
    constants: RuntimeValue<any>[],
    instructions: Instruction[],
    callback: (output: Output) => void,
) {
    let output = new MockOutput();
    let runtime = new Runtime(constants, instructions, { output });
    runtime.run();
    callback(output);
}