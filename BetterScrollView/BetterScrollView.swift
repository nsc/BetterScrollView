import SwiftUI

struct BetterScrollView<Content: View>: NSViewRepresentable {
    @ViewBuilder var content: Content
    
    class Coordinator {
        init(content: Content) {
            let documentView = NSHostingView(rootView: content)
            
            documentView.translatesAutoresizingMaskIntoConstraints = false
            documentView.layer?.borderColor = .init(red: 1, green: 0, blue: 0, alpha: 1)
            documentView.layer?.borderWidth = 1

            self.documentView = documentView
            
            let scrollView = NSScrollView()
            
            scrollView.autohidesScrollers = false
            scrollView.hasVerticalScroller = true
            scrollView.documentView = documentView
            
            self.scrollView = scrollView
        }
        
        var documentView: NSHostingView<Content>
        var scrollView: NSScrollView

        var clipView: NSClipView {
            scrollView.contentView
        }
        
        func update(with content: Content, context: Context) {
            let wasScrolledToBottom = clipView.isScrolledToBottom
            
            documentView.rootView = content
            
            if wasScrolledToBottom {
                clipView.scroll(to: CGPoint(x: 0, y: CGFloat.greatestFiniteMagnitude))
            }
            
            let visibility = unsafeBitCast(context.environment.verticalScrollIndicatorVisibility, to: UInt8.self)
            
            switch visibility {
            case unsafeBitCast(ScrollIndicatorVisibility.hidden, to: UInt8.self),
                unsafeBitCast(ScrollIndicatorVisibility.never, to: UInt8.self):
                scrollView.hasVerticalScroller = false
                
            case unsafeBitCast(ScrollIndicatorVisibility.visible, to: UInt8.self):
                scrollView.hasVerticalScroller = true
                scrollView.autohidesScrollers = false

            case unsafeBitCast(ScrollIndicatorVisibility.automatic, to: UInt8.self):
                scrollView.hasVerticalScroller = true
                scrollView.autohidesScrollers = true

            default:
                scrollView.hasVerticalScroller = true
                scrollView.autohidesScrollers = true
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(content: content)
    }

    func makeNSView(context: Context) -> NSScrollView {
        context.coordinator.scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.update(with: content, context: context)
    }
}

extension NSClipView {
    var isScrolledToBottom: Bool {
        guard let documentView else { return false }
        
        let bottomEdge = convert(CGPoint(x: 0, y: documentView.bounds.maxY), from: documentView).y
        
        return bottomEdge - 0.1 <= bounds.maxY
    }
}
