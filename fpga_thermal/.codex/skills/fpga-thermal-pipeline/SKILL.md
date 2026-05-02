---
name: fpga-thermal-pipeline
description: Build and maintain the Tang Nano 9K FPGA thermal preprocessing project for Tiny1-C raw streams, Verilog-2001 RTL, Gowin-friendly synthesis, simulation testbenches, packet formats, and ESP32-S3 handoff. Use when modifying this repo's FPGA image-processing pipeline, metadata extraction, packet transport, or related docs.
---

# FPGA Thermal Pipeline

## Workflow

1. Keep the FPGA role narrow: raw pixel receive, frame sync, grayscale normalization, ROI crop, scaling, Sobel edge enhancement, thumbnail/mask/meta extraction, and packet transmission to ESP32-S3.
2. Do not add AI inference, YOLO, ESRGAN, neural super-resolution, AMOLED driving, UI state machines, or ESP32-S3 firmware logic to the FPGA RTL.
3. Prefer Verilog-2001 and Gowin-friendly constructs. Keep each module in its own file under `rtl/`.
4. Preserve valid/data alignment. When a module adds latency, delay coordinates and frame flags with the pixel data.
5. Treat Tiny1-C pixels as opaque 16-bit raw containers unless the user provides a confirmed protocol document.
6. Maintain P0/P1 separation: P0 nearest-neighbor and simple high-byte normalization must remain easy to simulate; P1 fixed-point bilinear/min-max extensions must not break P0.
7. Update or add focused testbenches under `sim/` for behavioral changes.
8. Keep README packet format and module descriptions synchronized with RTL interfaces.

## Hardware Boundaries

- Tang Nano 9K has limited LUT/FF/BSRAM/DSP resources. Avoid full CNNs and large frame-level algorithms.
- Use shifts/adds for Sobel weights.
- Use fixed-point arithmetic for interpolation; never use floating point in RTL.
- Mark frame-buffered P0 blocks clearly if they are not final low-latency streaming implementations.

## Git Habit

After a coherent modification batch, run relevant validation and commit only project files under `fpga_thermal/`. Leave unrelated parent-repo files untouched.
