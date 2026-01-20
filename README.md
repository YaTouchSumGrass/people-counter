# People Counter
A school project to count the total amount of people who has entered or exited a building.

## How To Compile
You'll need to install Python on your machine.
You'll need to create a Python virtual environment. Run:
```bash
python3 -m venv .venv
```

Then activate the virtual environment. On macOS/Linux, run:
```bash
source .venv/bin/activate
```
On Windows:
```powershell
. .\.venv\Scripts\Activate.ps1
```

Then install PlatformIO. This is the tool I use to compile, upload, and monitor the board.
```bash
pip install platformio
```

Then in file platformio.ini, make sure to change the port there to your actual serial port.

To compile and upload, go inside the api directory and run:
```bash
pio run -t upload
```

To monitor, run:
```bash
pio device monitor
```

For the web view, you'll need the Gleam compiler to compile it.Check out https://gleam.run/getting-started/installing/ to see how you can install Gleam on your platform.

Then in the app and db directory, you can build it by running:
```bash
gleam run -m lustre/dev build
```

Checkout the source code as well, as they maybe things that you might want to adjust to fit your specifications. Primarily these files:
- app/gleam.toml
- api/platformio.ini
- api/src/Server.cpp
- apt/src/Sensors.cpp
