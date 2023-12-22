# PIC-8259
There are several issues and potential improvements in our Verilog code for the PIC 8259A implementation. Here we will highlight some of the issues and suggest corrections that we found after a comprehensive search:

1. **Bit_To_Num Module**: The `Bit_To_Num` module seems to be correct, but it's not used anywhere in the other modules. If it's intended to be used, you should replace the manual bit-to-number conversions with this module to make the code cleaner and more maintainable.

2. **Cascademodule**: The `Cascademodule` has several issues:
   - The `always @(IRR)` block should be sensitive to changes in `SP_EN` and `SNGL` as well, since the behavior depends on these signals.
   - The `always @ (*)` block should use non-blocking assignments (`<=`) instead of blocking assignments (`=`) for sequential logic.
   - The `cnt` signal should be declared as a multi-bit register if it's intended to count beyond 1.
   - The `always@(posedge INTA)` block should be sensitive to the negedge of `INTA` as well, or there should be a separate always block for the negedge.
   - The `flagCodeAddress` signal should be reset to 0 in a reset condition or at the beginning of the operation.

3. **Control_Logic Module**: This module has a lot of issues:
   - The `always @ (FlagFromRW or ReadWriteinputData)` block should use non-blocking assignments for sequential logic.
   - The `always @ (read2controlRW)` block should use a case statement instead of multiple if-else statements for better readability and synthesis.
   - The `always @(posedge INTA)` block should be sensitive to the negedge of `INTA` as well, or there should be a separate always block for the negedge.
   - The `always @ (InterruptID)` block should be sensitive to other signals that affect the `INT` signal.
   - The `always @(SpecialMaskModeFlag or CWregFile[4])` block should use a case statement instead of if-else statements.
   - The `Num_To_Bit` module is instantiated but not connected to the rest of the logic.

4. **DataBuffer Module**: The `DataBuffer` module has a few issues:
   - The `always @(*)` block should use non-blocking assignments for sequential logic.
   - The `assign` statements for `Data` and `InternalD` should not drive the same signals as the `always` block; this can cause contention.

5. **DataBuffer_TB**: This testbench module has a syntax error in the module instantiation. The `DataBuffer` module does not have a `buffer` port, so the connection to `buffer` is invalid.

6. **In_Service Module**: The `In_Service` module has issues:
   - The `always @(*)` block should use non-blocking assignments for sequential logic.
   - The `rotate_right` and `rotate_left` modules are instantiated but not connected to the rest of the logic.

7. **Interrupt_Request Module**: The `Interrupt_Request` module has issues:
   - The `always @(*)` blocks should use non-blocking assignments for sequential logic.
   - The `genvar` and `generate` block is not necessary; a simple `always @(*)` block can handle the logic.

8. **Num_To_Bit Module**: This module seems to be correct, but it's not used anywhere in the other modules.

9. **PIC_8259A Module**: This top-level module has issues:
   - The connections between submodules are not clear, and some signals are not driven or used.
   - The `Read_WriteLogic` module is not included in the provided code.

10. **PIC_8259_TestBench**: This testbench module has several issues:
    - The tasks are not called correctly; they should be called with the `task_name();` syntax.
    - The `TASK_SEND_ACK_TO_8086_SLAVE` task is commented out and not used.
    - The `TASK_INIT` task does not reset the `INT` signal.

11. **Priority_Resolver Module**: This module has issues:
    - The `always @*` block should use non-blocking assignments for sequential logic.
    - The `rotate_right` and `rotate_left` modules are instantiated but not connected to the rest of the logic.

12. **Read_WriteLogic Module**: This module is not provided, but it's referenced in the `PIC_8259A` module.

13. **resolve_priority Module**: This module seems to be correct, but it's not used anywhere in the other modules.

14. **rotate_left and rotate_right Modules**: These modules seem to be correct, but they are not connected to the rest of the logic in the `Priority_Resolver` module.

To address these issues, we should:
- Ensure that all always blocks that infer sequential logic use non-blocking assignments.
- Use case statements for better readability and synthesis where multiple conditions are checked.
- Connect instantiated modules properly and ensure that all signals are driven and used where necessary.
- Add a reset condition to initialize or reset the state of the registers.
- Review the sensitivity lists of always blocks to include all signals that affect the logic within the block.
- Remove unused code and modules to clean up the design.

Due to the complexity of the project and the number of issues, we decided to tackle each module separately, write testbenches for each one, and ensure they work as expected before integrating them into the top-level module.
