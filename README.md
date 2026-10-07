# Approximate Sobel Edge Detection — VLSI Implementation

An RTL-to-GDSII implementation study of an approximate Sobel edge-detection architecture using approximate multipliers.

The project compares three multiplier architectures:

- **Exact Multiplier** — reference implementation
- **OSA Multiplier** — Overlapped Segmentation Approximate multiplier
- **ETAI Multiplier** — Error-Tolerant Adder-based approximate multiplier

The designs are integrated into a Sobel gradient-magnitude computation and evaluated using **area, power, timing, setup slack, and image quality**.

---

## Project Overview

Sobel edge detection is widely used in image-processing applications to identify edges by calculating image intensity gradients.

The conventional Sobel operator requires multiple arithmetic operations, including multiplication and addition. Since arithmetic hardware contributes significantly to implementation complexity, approximate computing can be used to explore the trade-off between hardware cost and computational accuracy.

This project investigates that trade-off by implementing an exact multiplier and two approximate multiplier architectures and integrating them into a Sobel edge-detection datapath.

The complete designs are taken through an **RTL-to-GDSII flow using OpenLane and the SKY130A PDK**, allowing both application-level image-quality and physical-design metrics to be evaluated.

---

## Architecture

The project contains three main implementations:

| Architecture | Multiplier | Purpose |
|---|---|---|
| Exact | Exact multiplier | Reference implementation |
| OSA | OSA approximate multiplier | Reduce multiplication complexity |
| ETAI | ETAI approximate multiplier | Approximate low-order arithmetic |

The three architectures use the same Sobel datapath, allowing the effect of changing the multiplier architecture to be studied.

---

## Approximate Multiplier Architectures

### Exact Multiplier

The Exact implementation acts as the golden/reference architecture.

It uses the conventional multiplication operation and is used as the reference for:

- Hardware comparison
- Timing comparison
- Power comparison
- Image-quality evaluation

### OSA Multiplier

The OSA implementation uses **Overlapped Segmentation Approximation**.

Instead of multiplying the complete operand magnitudes, the architecture:

1. Determines the leading-one position of each operand.
2. Extracts a smaller segment around the leading one.
3. Performs an exact multiplication on the extracted segments.
4. Shifts the result back according to the original operand positions.
5. Discards information outside the selected segment.

For the evaluated implementation:

```text
W   = 8 bits
SEG = 4 bits
```

Therefore, the OSA architecture performs a smaller **4 × 4 segment multiplication** instead of a complete 8 × 8 multiplication, together with leading-one detection and reconstruction logic.

The segment size provides an accuracy-versus-complexity trade-off.

### ETAI Multiplier

The ETAI implementation uses an explicit array-multiplier structure with approximation introduced during partial-product accumulation.

The lowest `ERR_BITS` columns use an approximate full-adder structure in which the carry-in is ignored:

```text
sum   = a ^ b
carry = a & b
```

Higher-order columns remain exact.

For the evaluated implementation:

```text
W        = 8 bits
ERR_BITS = 4
```

This allows the effect of low-order arithmetic approximation to be studied while retaining exact computation in the higher-order portion of the accumulation.

---

## Sobel Processing

The Sobel operator uses horizontal and vertical gradient kernels:

```text
Gx = [-1   0  +1]
     [-2   0  +2]
     [-1   0  +1]

Gy = [-1  -2  -1]
     [ 0   0   0]
     [+1  +2  +1]
```

The gradient magnitude is approximated in hardware as:

```text
|G| ≈ |Gx| + |Gy|
```

The RTL implementation contains dedicated modules for:

- Multiplier selection
- Sobel multiply-accumulate computation
- Gradient calculation
- Gradient magnitude calculation
- Saturation
- Top-level Sobel processing

---

## RTL Modules

### Core RTL

```text
rtl/
├── sobel_top.v
├── sobel_mac.v
├── gradient_mag.v
├── mult_wrapper.v
├── exact_mult.v
├── osa_mult.v
├── etai_mult.v
├── leading_one_detector.v
└── segment_extract.v
```

### Synthesis Wrappers

```text
synth/
├── top_exact.v
├── top_osa.v
└── top_etai.v
```

The synthesis wrappers provide separate top-level configurations for comparing the three multiplier architectures.

---

## Verification

The Exact Sobel RTL was compared against an independent Python/NumPy golden model.

The Exact implementation produced:

```text
PSNR = ∞
MAE  = 0
```

indicating a bit-exact match with the reference model.

The RTL designs were also lint-checked and verified before physical implementation.

---

# Physical Design

The three designs were implemented through the OpenLane RTL-to-GDSII flow using the **SKY130A PDK**.

### OpenLane Configuration

The Sobel datapath is fully combinational and therefore does not contain a real clock.

The final configuration used:

```json
{
  "DESIGN_NAME": "<variant>",
  "VERILOG_FILES": "dir::src/*.v",
  "CLOCK_PORT": null,
  "RUN_CTS": false,
  "FP_CORE_UTIL": 30
}
```

### Final OpenLane Runs

| Variant | OpenLane Run |
|---|---|
| Exact | `RUN_2026.10.05_11.33.50` |
| OSA | `RUN_2026.10.05_11.42.27` |
| ETAI | `RUN_2026.10.05_11.49.58` |

All three implementations successfully reached final physical implementation and generated final physical-design outputs including GDSII.

---

# Results

## Physical Design Comparison

The final post-route results are:

| Metric | Exact | OSA | ETAI |
|---|---:|---:|---:|
| **Core Area (µm²)** | 17,779.55 | 25,181.65 | **17,296.59** |
| **Total Cells** | 2,379 | 3,385 | **2,267** |
| **Synthesized Cells** | 544 | 803 | **519** |
| **Wire Length** | 15,511 | 26,146 | **15,231** |
| **Vias** | 3,961 | 5,806 | **3,835** |
| **Internal Power (µW)** | 0.363 | 0.559 | 0.393 |
| **Switching Power (µW)** | 0.490 | 0.738 | **0.475** |
| **Leakage Power (mW)** | 3.99e-09 | 5.66e-09 | **3.87e-09** |
| **Critical Path (ns)** | **5.92** | 8.13 | 6.25 |
| **Suggested Frequency (MHz)** | **98.33** | 80.78 | 95.24 |
| **Setup Slack (ns)** | **-0.17** | -2.38 | -0.50 |
| **DRC Violations** | 0 | 0 | 0 |
| **LVS Violations** | 0 | 0 | 0 |

---

## Area

![Area Comparison](results/graphs/01_area_comparison.png)

The final physical core areas are:

```text
Exact : 17,779.55 µm²
OSA   : 25,181.65 µm²
ETAI  : 17,296.59 µm²
```

ETAI produces the smallest final core area among the three implementations.

An important observation is that **OSA becomes the largest physical implementation**, despite using a smaller segmented multiplication structure.

This demonstrates that reducing the complexity of the arithmetic operation does not necessarily guarantee a smaller final physical design. Additional logic such as leading-one detection, segmentation, shifting, and reconstruction contributes to the final implementation.

---

## Power

![Power Comparison](results/graphs/02_power_comparison.png)

The measured internal and switching power values are:

| Implementation | Internal Power (µW) | Switching Power (µW) |
|---|---:|---:|
| Exact | 0.363 | 0.490 |
| OSA | 0.559 | 0.738 |
| ETAI | 0.393 | 0.475 |

OSA has the highest measured internal and switching power among the three implementations.

ETAI remains relatively close to the Exact implementation while providing the smallest physical area.

---

## Timing

![Timing Comparison](results/graphs/03_timing_comparison.png)

The post-route critical-path delays are:

| Implementation | Critical Path (ns) | Suggested Frequency (MHz) |
|---|---:|---:|
| Exact | **5.92** | **98.33** |
| OSA | 8.13 | 80.78 |
| ETAI | 6.25 | 95.24 |

The Exact implementation has the shortest critical path, while OSA has the longest.

ETAI remains relatively close to the Exact implementation in post-route timing.

---

## Setup Slack

![Setup Slack Comparison](results/graphs/05_setup_slack_comparison.png)

The worst post-route setup slack values are:

| Implementation | Setup Slack (ns) |
|---|---:|
| Exact | **-0.17** |
| OSA | -2.38 |
| ETAI | -0.50 |

All three implementations have negative setup slack under the selected timing constraint.

Therefore, these designs should **not** be described as timing-clean signoff designs.

The timing results are instead used to compare the relative timing behavior of the three architectures.

OSA has the largest timing violation, while ETAI remains much closer to the Exact implementation.

---

## Image Quality

![Image Quality Comparison](results/graphs/04_image_quality_comparison.png)

The approximate implementations were compared against the Exact Sobel implementation.

| Implementation | PSNR | MAE |
|---|---:|---:|
| Exact | ∞ | 0 |
| OSA (SEG=4) | 32.47 dB | 4.08 |
| ETAI | ∞ | 0 |

### OSA Image Quality

The OSA implementation produces measurable image degradation:

```text
PSNR = 32.47 dB
MAE  = 4.08
```

The resulting edges remain recognizable, with a small visible degradation in the tested image.

The OSA segment-size sweep also demonstrates the accuracy-versus-approximation trade-off:

| OSA SEG | PSNR (dB) | MAE |
|---:|---:|---:|
| 2 | 21.12 | 8.145 |
| 3 | 23.10 | 6.714 |
| 4 | 32.47 | 4.082 |
| 5 | 34.28 | 3.302 |
| 6 | 45.03 | 0.514 |
| 7 | ∞ | 0.000 |

Smaller segment sizes introduce greater approximation error.

---

## Important ETAI Observation

An interesting result was observed for the ETAI implementation.

Inside the Sobel pipeline:

```text
PSNR = ∞
MAE  = 0
```

Therefore, the tested ETAI Sobel output was bit-identical to the Exact output.

However, this does **not** mean that ETAI is generally error-free.

Standalone random 8-bit multiplier testing produced:

```text
MED = 1.48
Affected outputs = 17.65%
```

The zero-error behavior inside the Sobel application is related to the structure of the Sobel coefficients:

```text
{-2, -1, 0, +1, +2}
```

These coefficients correspond primarily to shifts, sign changes, and zero operations. Consequently, the approximate carry chains in the ETAI multiplier are not exercised in the same way as they are for generic multiplication operands.

This demonstrates that the effect of an approximate multiplier depends not only on its arithmetic error characteristics, but also on the operand characteristics of the target application.

---

# Key Findings

### 1. ETAI achieved the smallest physical area

```text
Exact = 17,779.55 µm²
OSA   = 25,181.65 µm²
ETAI  = 17,296.59 µm²
```

ETAI also used the fewest final cells.

### 2. OSA became the largest and slowest implementation

Despite using a smaller segmented multiplication structure, OSA produced:

```text
Largest area      = 25,181.65 µm²
Longest path      = 8.13 ns
Worst slack       = -2.38 ns
Highest power     = 0.559 µW internal
```

This highlights the effect of additional segmentation and reconstruction logic in the physical implementation.

### 3. ETAI remained close to Exact in timing

```text
Exact = 5.92 ns
ETAI  = 6.25 ns
OSA   = 8.13 ns
```

### 4. ETAI produced zero measured Sobel error

For the tested image:

```text
ETAI PSNR = ∞
ETAI MAE  = 0
```

while standalone testing confirms that ETAI itself is still an approximate multiplier.

### 5. RTL-level expectations do not necessarily predict post-layout results

The OSA result is particularly important because its arithmetic simplification does not translate into improved final area, power, or timing.

This demonstrates why approximate architectures should be evaluated through the complete physical-design flow rather than only through RTL simulation or generic synthesis.

---

# Physical Layout

The final GDSII layouts were generated and visualized using KLayout.

## Exact Implementation

![Exact Layout](results/layout/top_exact_layout.png)

## OSA Approximate Implementation

![OSA Layout](results/layout/top_osa_layout.png)

## ETAI Approximate Implementation

![ETAI Layout](results/layout/top_etai_layout.png)

All three implementations achieved:

```text
DRC violations = 0
LVS violations = 0
```

---

# Design Trade-off

Approximate computing introduces a fundamental trade-off:

```text
Approximation
      ↓
Modified arithmetic complexity
      ↓
Different physical PPA characteristics
      ↓
Controlled numerical error
      ↓
Possible image-quality degradation
```

However, the results of this project show that this relationship is not always straightforward.

For example:

```text
OSA
 ↓
Smaller segmented multiplication
 ↓
Additional LOD + segmentation + reconstruction logic
 ↓
Larger physical area and longer critical path
```

while:

```text
ETAI
 ↓
Approximation in low-order accumulation
 ↓
Smallest final physical implementation
 ↓
Zero measured Sobel error for the tested image
```

Therefore, the best approximate architecture depends on both the **hardware implementation** and the **application workload**.

---

# Evaluation Metrics

The architectures are evaluated using:

### Area

Measures the physical core area required by each implementation.

### Power

Internal and switching power are compared after physical implementation.

### Timing

Critical-path delay and suggested operating frequency are used to compare timing performance.

### Setup Slack

Setup slack indicates the timing margin relative to the selected timing requirement.

A negative setup slack indicates that the corresponding timing requirement is not met.

### Image Quality

The approximate Sobel outputs are compared against the Exact reference using:

- PSNR
- Mean Absolute Error (MAE)

---

# Tools and Technologies

- Verilog HDL
- RTL Design
- Approximate Computing
- Digital VLSI Design
- Sobel Edge Detection
- OpenLane
- SKY130A PDK
- Yosys
- OpenROAD
- KLayout
- Verilog Simulation
- Python
- NumPy
- Pillow

---

# Repository Structure

```text
approx-sobel-vlsi/
│
├── rtl/
│   ├── sobel_top.v
│   ├── sobel_mac.v
│   ├── gradient_mag.v
│   ├── mult_wrapper.v
│   ├── exact_mult.v
│   ├── osa_mult.v
│   ├── etai_mult.v
│   ├── leading_one_detector.v
│   └── segment_extract.v
│
├── synth/
│   ├── top_exact.v
│   ├── top_osa.v
│   └── top_etai.v
│
├── openlane/
│   ├── top_exact/
│   │   └── config.json
│   ├── top_osa/
│   │   └── config.json
│   └── top_etai/
│       └── config.json
│
├── results/
│   ├── graphs/
│   │   ├── 01_area_comparison.png
│   │   ├── 02_power_comparison.png
│   │   ├── 03_timing_comparison.png
│   │   ├── 04_image_quality_comparison.png
│   │   └── 05_setup_slack_comparison.png
│   │
│   └── layout/
│       ├── top_exact_layout.png
│       ├── top_osa_layout.png
│       └── top_etai_layout.png
│
└── README.md
```

---

# Objective

The main objective of this project is to investigate whether approximate arithmetic can provide useful hardware benefits for an image-processing application while maintaining acceptable application-level accuracy.

The study compares:

```text
Exact Multiplier
       │
       ├──────────────┐
       ↓              ↓
     OSA             ETAI
       │              │
       └──────┬───────┘
              ↓
       Sobel Edge Detection
              ↓
      Image Quality Analysis
              ↓
        RTL-to-GDSII
              ↓
    Area / Power / Timing
```

The final evaluation demonstrates that the relationship between arithmetic approximation and physical PPA depends strongly on the architecture and the target application.

---

# Future Work

Possible extensions include:

- Evaluate the architectures across a larger and more diverse image dataset.
- Investigate the zero-error ETAI behavior across different Sobel inputs.
- Explore different OSA segment sizes for additional PPA/quality trade-offs.
- Explore different ETAI approximation depths.
- Investigate pipelined or streaming Sobel architectures to improve timing.
- Evaluate additional approximate multiplier architectures.
- Perform FPGA implementation.
- Compare implementations across different technology nodes.
- Perform further physical optimization to reduce timing violations.

---

# Author

**Manish Mogaveera**  
Electronics and Communication Engineering  
Dayananda Sagar College of Engineering, Bengaluru

---

# License

This project is intended for academic, research, and educational purposes.
