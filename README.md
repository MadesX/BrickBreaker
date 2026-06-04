# BrickBreaker FPGA Game

A hardware-based implementation of the classic BrickBreaker (Breakout) game, built for an FPGA environment using VHDL and SystemVerilog. 
The system features fully integrated VGA display output, Bluetooth controller support via an Android application, and background audio processing.

# System Architecture & Modules

To maintain a clean and testable design, the core components of this system are separated into isolated sub-modules. Each module contains its own source code and dedicated testbench (`tb`) files for independent simulation.

* **`modules/UART/`:** The foundational Universal Asynchronous Receiver-Transmitter module handling raw serial data transmission and reception.
* **`modules/hexcon/`:** Built on top of the UART module, this SystemVerilog unit decodes incoming Bluetooth serial data from the Android application to stabilize and translate player inputs.
* **`modules/mp3_player/`:** Interfaces with the external SD card audio module via UART to trigger and manage background music playback.
* **`modules/screens/`:** Contains the VGA generation logic for the distinct visual states, including the main menu, the active gameplay rendering, and the dynamic end-game (Victory/Defeat) displays.
* **`src/BrickBreaker_top.vhd`:** The top-level VHDL entity. It instantiates the modules above and runs the master finite state machine to route signals between the Bluetooth controller, the audio player, the VGA screens, and the core game physics.

# Key Features

* **Hardware VGA Generation:** Direct rendering of bricks, ball, paddles, and text elements using standard VGA timing principles.
* **Dynamic Physics:** The ball's speed and trajectory change dynamically depending on exactly where it strikes the paddle (center vs. edges).
* **Wireless Control:** Full menu navigation and bottom paddle control using the "Bluetooth Serial Controller" mobile app.
* **Local Multiplayer:** Two-player mode where Player 1 uses Bluetooth (left/right) and Player 2 uses physical FPGA board buttons (button1/button2).
* **Signal Stabilization:** Includes a `pulse_reg` unit to stabilize and extend the input signals coming from the Bluetooth controller.

# How to Use

**Important:** Keep all files in their original directories and do not rename the provided asset files.

**1. Hardware Setup**
* Connect the VGA cable, AUX audio cable, and Add-On board to your FPGA.
* Load the provided MP3 background tracks onto a Micro SD card and insert it into the MP3 module.
* Connect the FPGA board to your computer.

**2. Controller Setup**
* Download and install the "Bluetooth Serial Controller" application on your Android device from the provided zip file.
* Load the custom `controller` configuration file into the app.
* Tap the magnifying glass icon in the app and pair it with the `See-Sys - Bluetooth` module on the board.

**3. Compilation & Execution**
* Compile the project software in Quartus and flash the resulting bitstream onto the board.
* Use the Bluetooth controller's `up`, `down`, and `select` buttons to navigate the main menu. 
* Enjoy the game!

# System States

The main `BrickBreaker` entity operates on a finite state machine covering the following states:
* `Pre`: System initialization and MP3 setup.
* `menu`: Idle state awaiting player mode selection.
* `breaker_1p`: Single-player active gameplay state.
* `breaker_2p`: Two-player active gameplay state.
* `Screen`: End-game resolution (Victory/Defeat) waiting for restart command.

# License

This project is licensed under a custom license:

You may use, copy, and modify the code for **personal or non-profit purposes** for free.  
If you wish to use the code in **any commercial or for-profit product**, you must contact the author and may be required to pay a fee or share profits.

© 2025 Matan Sides  
All rights reserved.
