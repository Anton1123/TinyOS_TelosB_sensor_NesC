# TinyOS_TelosB_sensor_NesC
A repository for modules and configurations written in NesC relating to Wireless Sensor Programming of the TelosB sensor running TinyOS. Current implementation is used the read the sensor data from a Crossbow TelosB sensor, in particular: temperature (in Fahrenheit), luminosity, and humidity percentage.

TinyOS must be installed on the PC. 

To Install/Run:
1. Plug in sensor into USB port.
2. Move into the directory containing the .nc files.
3. For clean slate, run command $ make clean .
4. To install current configurations/modules, run command $ make telosb install .

To view readings:
1. Download "Serial Port Terminal" from Ubuntu Software Center.
2. Run Serial Port Terminal.
3. Go to Configuration -> Port.
4. Change Port to the appropriate name of the USB port that the sensor is plugged into. This can be found after running command $ motelist .
5. Change Baud Rate to 115200.

