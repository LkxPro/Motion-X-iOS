# Motion X iOS

Motion X is an iOS application designed to capture and visualize device motion data such as `roll`, `pitch`, `yaw` and `acceleration` using the device's inbuilt sensors. 

The app also features the capability to send this data over a `WebSocket` connection to a specified server address and port.

<video width="100%" max-height="500px" autoplay loop muted>
  <source src="demo.mov" type="video/mp4" />
  <source src="demo.png" type="image/png" />
</video>

## Features
- **Real-Time Motion Data Capture:** Captures `roll`, `pitch`, `yaw` and `acceleration` data using Core Motion
 framework in real-time.

- **WebSocket Communication:** Sends motion data to a server via `WebSocket` protocol.

- **Data Visualization:** Displays the ootion data graphically in a line chart format.

- **User Interface:** Simple and intuitive interface for connecting to the server and displaying motion data.

## Installation
Motion X iOS is currently yet uploaded to the App Store. We will need to build it from the source.

## Build from source
1. Clone the repository
2. Open the Motion X.xcodeproj file in Xcode.
3. Connect your iOS device to your computer.
4. Select your device as the build destination in Xcode.
5. Press the Run button to build and install the app on your device

## Sent data to server
Install Node.js

    brew install node

Create a server.js file

```js
const WebSocket = require('ws');

const port = 8080;
const server = new WebSocket.Server({ port });

console.log(`WebSocket server is running on ws://localhost:${port}`);

server.on('connection', (ws) => {
  console.log('Client connected');

  ws.on('message', (message) => {
    console.log(`Received: ${message}`);
    // Broadcast the message to all other connected clients
    server.clients.forEach((client) => {
      if (client !== ws && client.readyState === WebSocket.OPEN) {
        client.send(message);
      }
    });
  });

  ws.on('close', () => {
    console.log('Client disconnected');
  });
});

```

Install WebSocket library

    npm install ws

Start server.js

    server.js

## License
Motion X is licensed under the [Apache License
 2.0](LICENSE).