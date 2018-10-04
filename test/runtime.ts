/// <reference path="../node_modules/@types/mocha/index.d.ts" />
import { value, op, programWithOutput, reg, cst } from "../src/runtime";
import * as assert from "assert";

describe("A program that prints a number", () => {
    it("outputs the number printed", () => {
        programWithOutput([
            value(42),
            value("\n"),
        ], [
            op.Load(reg(0), cst(0)),
            op.Print(reg(0)),
            op.Load(reg(1), cst(1)),
            op.Print(reg(1)),
        ], (output) => {
            assert.equal(output.toString(), "42\n");
        });
    });
});