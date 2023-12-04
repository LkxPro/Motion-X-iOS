# Motion X iOS

Motion X is an iOS application designed to capture and visualize device motion data such as `roll`, `pitch`, `yaw` and `acceleration` using the device's inbuilt sensors. 

The app also features the capability to send this data over a `WebSocket` connection to a specified server address and port.

https://github.com/LkxPro/Motion-X-iOS/assets/20046257/59233619-5f04-444b-8ef8-7bd83a953daa

## Features
- **Real-Time Motion Data Capture:** Captures `roll`, `pitch`, `yaw` and `acceleration` data using Core Motion
 framework in real-time.

- **WebSocket Communication:** Sends motion data to a server via `WebSocket` protocol.

- **Data Visualization:** Displays the motion data graphically in a line chart format.

- **User Interface:** Simple and intuitive interface for connecting to the server and displaying motion data.

## Installation
Motion X iOS is currently not yet uploaded to the App Store. We will need to build it from the source.

## Build from source
Clone the repository

    git clone https://github.com/LkxPro/Motion-X-iOS.git

Open the `Motion X.xcodeproj` file in Xcode.

Connect your iOS device to your computer.

Select your device as the build destination in Xcode.

Press the Run button to build and install the app on your device

## Setting Up the Server
Install Node.js

    brew install node

Install WebSocket library

    npm install ws

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

Start server.js

    npm server.js

Enter the server address and port on the Motion X iOS App, then click 'Connect'. The server will now start receiving motion data.

## License
Motion X iOS is licensed under the [Apache License 2.0](LICENSE).
