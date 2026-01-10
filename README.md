# People Counter
A school project to count the total amount of people who has entered or exited a building.

## How To Compile
You'll need to install Python on your machine.
Inside the Api directory, you'll need to create a Python virtual environment. Run:
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

To compile and upload, run:
```bash
pio run -t upload
```

To monitor, run:
```bash
pio device monitor
```

Checkout the source code as well, as they maybe things that you might want to adjust to fit your specifications.
