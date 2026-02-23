# UVM FIFO Verification Environment

##  Overview

This project implements a **UVM-based verification environment** for a FIFO (First-In-First-Out) design using **SystemVerilog and UVM**.

The environment verifies FIFO functionality through:

* Randomized testing
* Corner-case scenarios
* Scoreboarding
* Register model integration
* Functional checking and monitoring

The goal of this project is to demonstrate a structured and reusable UVM verification architecture for digital designs.

---

##  Project Structure

### 🔹 Design

* `design.sv` — FIFO RTL implementation

### 🔹 Interface

* `fifo_if.sv` — Interface connecting DUT and UVM environment

### 🔹 UVM Components

* `fifo_item.sv` — Transaction class
* `fifo_sequencer.sv` — Sequencer
* `fifo_driver_base.sv` — Driver
* `fifo_monitor.sv` — Monitor
* `fifo_agent.sv` — Agent
* `fifo_env.sv` — Environment
* `fifo_scoreboard.sv` — Scoreboard

### 🔹 Sequences

* `fifo_seq_base.sv` — Base sequence
* `fifo_random_seq.sv` — Randomized stimulus
* `fifo_seq_corner.sv` — Corner-case stimulus

### 🔹 Tests

* `fifo_base_test.sv` — Base test
* `fifo_test_random.sv` — Random test
* `fifo_test_corner.sv` — Corner-case test

### 🔹 Register Model

* `fifo_reg_model.sv` — UVM register model
* `fifo_reg_adapter.sv` — Register adapter

### 🔹 Top-Level Testbench

* `testbench.sv` — Top-level module integrating DUT and UVM

---

## Verification Features

* UVM layered architecture (Agent, Environment, Scoreboard)
* Constrained random stimulus
* Directed corner-case testing
* FIFO data integrity checking
* Register model integration
* Reusable and scalable structure

---

## Verification Goals

The environment verifies:

* Correct FIFO write/read behavior
* Data ordering (FIFO property)
* Full and empty flag correctness
* Corner conditions (overflow/underflow)
* Reset behavior

---

## Technologies Used

* SystemVerilog
* UVM (Universal Verification Methodology)
* Register Layer Modeling (RAL)

