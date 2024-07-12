

## Prerequisite
This is the artifact for paper "RTL Verification for Secure Speculation Using Contract Shadow Logic" to appear at ASPLOS 2025.
Running the code requires to install [Cadence Jaspergold FPV App](https://www.cadence.com/en_US/home/tools/system-design-and-verification/formal-and-static-verification/jasper-gold-verification-platform/formal-property-verification-app.html).

## Artifact Introduction
This artifact includes the code to verify 4 processors, SimpleOoO, Sodor, Ridecore and BOOM, under two contracts, sandboxing and constant-time.
For the first three, both the baseline scheme (4-copy) and our optimized scheme (2-copy) are implemented. For BOOM, we only implement the 2-copy scheme.
The code to reproduce the figures and tables are under `results`. Please read the artifact appendix in the paper for a step-by-step instruction.

### SimpleOoO
- SimpleOoO is an in-house simple Out-of-Order processor with various spectre defenses implemented.
- The source code can be found under `src/simpleooo`. By setting macros in `src/simpleooo/param.v`, various spectre defenses can be enabled. It includes the code for both baseline and optimized schemes.
- `src/simpleooo_1cycle` contains ISA machine (1-cycle version) of SimpleOoO, which will be used in the baseline scheme.
- To reproduce the result in Table 2 and 3, run `python3 verification/run_CompareTable.py` will print out commonds you need to execute to generate all data points. You can collect the timing information from the \*.log files.
- To reproduce the result in Figure 6, run `python3 verification/run_ScalabilityFigure.py` will print out commonds you need to execute to generate all data points. Put the collected timing information into `plot/Figure6.py` and then you can re-plot Figure 6.


### Sodor
- [Sodor](https://github.com/ucb-bar/riscv-sodor) is an open-source in-order processor that implements RV32I. We use its 2-stage version here.
- The source code of Sodor can be found under `src/sodor2`. It includes the code for both baseline and optimized schemes.
- The hardware parameters such as register numbers can be adjusted in `src/sodor2/param.vh`.
- For verification, e.g., the two-copy (optimized) verification scheme under constant-time contract, run `jaspergold verification/verify_2_copy_ct_sodor2.tcl`.
- Similarly, to run the four-copy (baseline) verification scheme under sandboxing contract, run `jaspergold verification/verify_4_copy_sandbox_sodor2.tcl`.

### Ridecore
- [Ridecore](https://github.com/ridecore/ridecore) is an open-source out-of-order processor that implements 35 instructions in RV32IM.
- The source code of Ridecore can be found under `src/ridecore`. It includes the code for both baseline and optimized schemes.
- `src/ridecore_1cycle` contains ISA machine (1-cycle version) of Ridecore, which will be used in the baseline scheme.
- The hardware parameters can be adjusted in `src/ridecore/constants.vh` (for ridecore) and `src/ridecore_1cycle/param.v` (for ridecore-1cycle).
- For verification, e.g., the two-copy (optimized) verification scheme under constant-time contract, run `jaspergold verification/verify_2_copy_ct_ridecore.tcl`.
- Similarly, to run the four-copy (baseline) verification scheme under sandboxing contract, run `jaspergold verification/verify_4_copy_sandbox_sodor2.tcl`.

### BOOM
- [BOOM](https://boom-core.org) is an open-source out-of-order processor that implements RV64GC.
- The source code of BOOM can be found under `src/boom`. Only the optimized scheme is implmented.
- For verification, e.g., the two-copy (optimized) verification scheme under constant-time contract, run `jaspergold verification/verify_2_copy_ct_boom.tcl`.
- On BOOM we try to find attacks due to different mis-speculation sources. Uncomment corresponding assumptions to do that. For example, if we directly tune the above command, Jaspergold will find an attack caused by exception due to address misalignment. Then, if we uncomment the assumption that "there's no exception caused by address misalignment" in `verification/verify_2_copy_ct_boom.tcl`, then in the verification it will find another attack caused by a different mis-speculation source.
