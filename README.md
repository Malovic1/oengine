# OENGINE

OENGINE is a small "game engine" inspired by **GoldSrc** and the **Quake** engine.  
It is written in the **[Odin programming language](https://odin-lang.org/)**.  
Tested with compiler version: `dev-2025-06`

The engine uses the **[Raylib](https://www.raylib.com/)** framework (currently version 5.0, with plans to upgrade to 5.5).

---

## Editor

- In-development editor for creating maps in a custom format or JSON.
- Loads collidable map geometry from `.obj` files (tested mostly with **TrenchBroom**).
- Supports texturing and entity placement via the custom editor.
- Planned support for `.map` files from **TrenchBroom**, enabling full integration.

---

## Platforms

- **Windows** and **Linux** (Ubuntu) are tested and working.
- **macOS** is compilable but not fully tested.
- Engine is intended for **personal use and learning game engine development**.

---

## How to Run

1. **Requirements**:
   - [Odin compiler](https://odin-lang.org/) (version `dev-2025-06` recommended)
   - Python (for running `run.py` but also optional because .bat and .sh files can be executed)

2. **Compiling**:
   - Run `run.py`, or use the `.bat`/`.sh` scripts in the platform-specific directories (`windows`, `linux`, `mac`).
   - After compilation, the executable will be located in the corresponding platform directory.

3. **Running Without Compiling**:
   - If you don’t have the Odin compiler, run the precompiled executable in the platform directory.
   - If the executable is missing, you'll need to compile it yourself.

---

## Notes

This project is under active development. Features and stability may change frequently.
