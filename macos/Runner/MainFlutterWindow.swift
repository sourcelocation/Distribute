import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    
    private let desiredTitleBarHeight: CGFloat = 32
    private var buttons: [NSButton] = []
    
    // Store original X positions to prevent drift/accumulation of offsets
    private var initialButtonXPositions: [NSButton: CGFloat] = [:]
    
    // Use NSTitlebarAccessoryViewController to adjust title bar height
    public let titlebarAccessoryViewController = NSTitlebarAccessoryViewController()
    
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        
        // Window styling
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.styleMask.insert(.fullSizeContentView)
        
        // Capture standard buttons
        buttons = [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton].compactMap {
            standardWindowButton($0)
        }
        
        // Calculate needed accessory height to reach desired title bar height
        let currentTitleHeight = self.contentRect(forFrameRect: self.frame).height - self.contentLayoutRect.height
        let accessoryHeight = max(0, desiredTitleBarHeight - currentTitleHeight)
        
        if accessoryHeight > 0 {
            let view = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: accessoryHeight))
            titlebarAccessoryViewController.view = view
            titlebarAccessoryViewController.layoutAttribute = .bottom
            self.addTitlebarAccessoryViewController(titlebarAccessoryViewController)
        }
        
        // Observers for fullscreen
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillEnterFullScreen(_:)), name: NSWindow.willEnterFullScreenNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillExitFullScreen(_:)), name: NSWindow.willExitFullScreenNotification, object: self)
        
        RegisterGeneratedPlugins(registry: flutterViewController)
        super.awakeFromNib()
    }
    
    override public func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        let currentHeight = self.contentRect(forFrameRect: self.frame).height - self.contentLayoutRect.height
        
        // Capture default positions if not yet captured
        // We only do this if we haven't modified them yet (i.e., known empty state)
        // OR we can trust super.layoutIfNeeded to reset them? 
        // Safer to capture once.
        if initialButtonXPositions.isEmpty {
            for button in buttons {
                if button.frame.origin.x > 0 {
                    initialButtonXPositions[button] = button.frame.origin.x
                }
            }
        }
        
        for button in buttons {
            let buttonHeight = button.frame.height
            let newY = (currentHeight - buttonHeight) / 2.0
            
            // Use captured X + 6px gap
            if let startX = initialButtonXPositions[button] {
                button.setFrameOrigin(NSPoint(x: startX + 6, y: newY))
            } else {
                // Fallback (keep existing X)
                button.setFrameOrigin(NSPoint(x: button.frame.origin.x, y: newY))
            }
        }
    }
    
    @objc func windowWillEnterFullScreen(_ notification: Notification) {
        titlebarAccessoryViewController.isHidden = true
        // Clear cached positions so we can re-acquire correct defaults when exiting
        initialButtonXPositions.removeAll()
    }

    @objc func windowWillExitFullScreen(_ notification: Notification) {
        titlebarAccessoryViewController.isHidden = false
        // Positions will be re-captured in layoutIfNeeded
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
