import Foundation

let delegate = HelperDelegate()
let listener = NSXPCListener(machServiceName: "com.kristoff.MacStatusHelper")
listener.delegate = delegate
listener.resume()

// Keep the daemon alive
RunLoop.main.run()
