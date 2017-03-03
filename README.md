# SocketIOBox
iOS Swift Socket.IO client that actually uses the Javascript client underneath acting as a wrapper.

#### Usage:

```swift
var socketBox = SocketIOBox(delegate: self, url: URL(string: "[SERVER_SOCKETIO_URL]")!, token: "[YOUR AUTH TOKEN]")
        
socketBox.on("message") { data in
    // Do whatever with data
}

_ = socketBox.beginConnection()
```

Disclaimer: This project is just for fun and not intended for real use unless something is really wrong. You should always use the Swift client.
