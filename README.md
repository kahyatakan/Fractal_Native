# Fractal_Native 🚀

**High-Performance Fractal Generator** using Julia (StaticCompiler) as a computation engine and Python as a driver.

This project demonstrates how to compile **Julia** code into tiny (~12 KB), dependency-free standalone libraries (`.so`) and call them from **Python** with zero overhead using `ctypes`.

## 🌟 Features
- **Ultra Lightweight:** No Julia Runtime required at execution. The compiled binary is ~12 KB.
- **Blazing Fast:** Generates 1,000,000 points in ~5ms.
- **Flexible:** The engine is generic; Python defines the fractal rules (IFS), Julia computes the math.

## 🛠️ Installation & Usage

### 1. Prerequisites
- Julia (v1.9+)
- Python (v3.8+)

### 2. Build the Engine (Julia)
Compiles the generic IFS engine into a shared library.
```bash
julia --project="." build_scripts/compile.jl
```

### 3. Run the Visualizer (Python)
Setup the environment and generate fractals.
```bash
# Create env
python -m venv fractal_env<img width="2278" height="1269" alt="LevyC" src="https://github.com/user-attachments/assets/2c870536-b056-482c-b526-6ff305bfe951" />

source fractal_env/bin/activate
pip install numpy matplotlib

# Run Demos
python dragon.py
```

## 🎨 Gallery
<img width="2278" height="1269" alt="LevyC" src="https://github.com/user-attachments/assets/eac89e46-91cf-47c4-93a9-533ff4326656" />

<img width="1000" height="1000" alt="Fern" src="https://github.com/user-attachments/assets/f1e4156a-da5f-4664-87d5-5e5a463ac858" />

<img width="1200" height="800" alt="Dragon" src="https://github.com/user-attachments/assets/79a29380-f2c3-49f9-a448-c2e98a66211a" />

--note that this readme is promoted by llm---
