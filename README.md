# Softmax IP Verification Platform

![UVM](https://img.shields.io/badge/UVM-SystemVerilog-blue)
![Coverage](https://img.shields.io/badge/Functional%20Coverage-92%25-brightgreen)
![Code Coverage](https://img.shields.io/badge/Code%20Coverage-99%25-success)

> A reusable UVM-based verification platform for a parameterized Softmax IP core.

This project provides a complete **UVM verification environment** for a parameterized Softmax accelerator.

The original project only contained a traditional Verilog testbench. The verification environment was redesigned and extended into a reusable UVM architecture, including stimulus generation, an independent golden reference model, scoreboard, functional coverage, regression scripts, and verification documentation.

---

## Project Highlights

- Reusable UVM verification architecture
- Independent Golden Reference Model
- Parameterized verification supporting different vector sizes
- Functional coverage driven verification
- Runtime reset verification
- Corner case verification
- Stream mode verification
- Automated regression scripts
- Comprehensive verification documentation

# Verification Architecture

<img width="607.5" height="648" alt="72aec8f7-810a-460f-91b2-9b834eb2eb31" src="https://github.com/user-attachments/assets/0eee9ee9-3172-4871-83e3-001c743b6674" />

---

# Directory Structure

```text
.
├── rtl/                      RTL implementation
├── tb/                       UVM verification environment
│   ├── agent/
│   ├── cfg/
│   ├── coverage/
│   ├── driver/
│   ├── env/
│   ├── monitor/
│   ├── reference_model/
│   ├── scoreboard/
│   ├── sequence/
│   ├── sequencer/
│   ├── test/
│   └── transaction/
├── docs/                     Verification documents
├── sim/                      Simulation scripts
└── README.md
```

---

# Verification Methodology

The verification platform follows a standard UVM architecture.

Verification flow:

1. Generate randomized transactions.
2. Driver converts transactions into DUT interface signals.
3. Monitor captures DUT input/output transactions.
4. Golden Reference Model generates expected outputs.
5. Scoreboard compares DUT outputs with reference outputs.
6. Functional coverage measures verification completeness.
7. Regression scripts execute multiple verification scenarios automatically.

---

# Verification Features

## Supported Testcases

- Base Test
- Random Test
- Corner Case Test
- Runtime Reset Test
- Stream Mode Test
- Parameter Regression

---

## Functional Coverage

The functional coverage focuses on the following verification points:

- Input value distribution
- Maximum element position
- Dynamic range
- Zero input
- Equal maximum values (Tie-Max)
- Boundary values
- Different operation modes
- Cross coverage between critical scenarios

Detailed coverage planning can be found in:

```text
docs/Coverage_Testpoints.md
```

---

# Golden Reference Model

An independent behavioral reference model is implemented to generate the expected Softmax outputs.

Features include:

- Fixed-point to floating-point conversion
- Softmax computation using real-number arithmetic
- Floating-point normalization
- Quantization back to fixed-point format

The reference model is fully independent from the RTL implementation, helping avoid common-mode verification failures.

---

# Scoreboard

The scoreboard automatically compares DUT outputs against reference model outputs.

Collected statistics include:

- Total transactions
- Passed transactions
- Failed transactions
- Error classification
- Lane mismatch statistics
- Runtime reset flushing
- Verification summary

---

# Regression

Regression scripts are provided for automated verification.

Example:

```bash
cd sim
./run_parameter_regression.sh
```

The regression supports multiple parameter configurations and automatically generates coverage reports.

---

# Documentation

Detailed verification documents are provided under the `docs` directory.

| Document                | Description                  |
| ----------------------- | ---------------------------- |
| RTL_spec.md             | RTL specification            |
| Coverage_Testpoints.md  | Functional coverage planning |
| Verification_Report.pdf | Verification report          |
| coverage_report.tar     | Coverage report              |

---

# My Contributions

The original project only contained a basic Verilog testbench.

I redesigned the verification flow and implemented a complete reusable UVM verification platform, including:

- UVM Environment
- Driver / Monitor / Agent
- Transaction & Sequence
- Golden Reference Model
- Scoreboard
- Functional Coverage
- Runtime Reset Verification
- Regression Scripts
- Verification Documentation

The RTL implementation was preserved, while the entire verification methodology was reconstructed following UVM best practices.

---

# Author

**dyZhang @IHEP,CAS  ,  W.Shao @IMECAS** 

Digital IC Verification / Digital IC Design

---

## License

This project is intended for educational and research purposes.
