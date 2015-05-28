## SerialPlotter

SerialPlotter is a slightly modified version of Sebastian Nilsson's RealtimePlotter.

It is useful to debug Arduino sensor inputs for those of us who are visually minded and prefer a graphical representation over a data log. This tool plots the numbers being pumped through serial instead of just printing them as text like the serial console does. It will hopefully make your life easier.

![Realtime plotter](http://sebastiannilsson.com/wp-content/uploads/2013/12/RealtimePlotterProcessing-300x216.png)

- Real-time plotter of your data while it is still being processed by your application
- Plots live data from serial port. Choice of microcontroller does not matter as long as it can send serial data to your computer.
- 6 channels of data
- Live bar charts
- Live line graphs
- You just send the data you want to debug with a space as delimiter like this "value1 value2 value3 value4 value5 value6". Floats or integers does not matter.
- Open source
- Robust. It will not crash because of corrupt data stream or similar.
- Multi platform Java. Tested on OSX and Windows 8 (and should work on Linux as well).

## How to use

Your arduino sketch needs to output the numbers of the different readings separated by a space and each reading must be separated from the next by the linebreak `\r` character.

Example:
```
Serial.print(digitalRead(A0));
Serial.println(" ");
Serial.print(digitalRead(A1));
Serial.println(" ");
Serial.print(digitalRead(A2));
Serial.println(" ");
Serial.print(digitalRead(A3));
Serial.println(" ");
Serial.print(digitalRead(A4));
Serial.print('\r');
```

When the sketch starts, just select the arduino serial device from the dropdown and the data rate, then enable data capture using the top left switch, you will hopefully see data streaming in.