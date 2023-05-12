import SwiftUI

struct BetterScrollView<Content: View>: NSViewRepresentable {
    @ViewBuilder var content: Content

    class Coordinator {
        init(content: Content) {
            let scrollView = NSScrollView()
            let wrappedContent = DocumentView(platformScrollView: scrollView, content: content)
            let documentView = NSHostingView(rootView: wrappedContent)

            documentView.translatesAutoresizingMaskIntoConstraints = false
            documentView.layer?.borderColor = .init(red: 1, green: 0, blue: 0, alpha: 1)
            documentView.layer?.borderWidth = 1

            self.documentView = documentView

            scrollView.autohidesScrollers = false
            scrollView.hasVerticalScroller = true
            scrollView.documentView = documentView
            
            self.scrollView = scrollView
        }
        
        var documentView: NSHostingView<BetterScrollView<Content>.DocumentView>
        var scrollView: NSScrollView

        var clipView: NSClipView {
            scrollView.contentView
        }
        
        func update(with content: Content, context: Context) {
            let wasScrolledToBottom = clipView.isScrolledToBottom
            
            documentView.rootView = DocumentView(platformScrollView: scrollView, content: content)
            
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

extension BetterScrollView {
    struct DocumentView: View {
        var platformScrollView: NSScrollView
        var content: Content

        var body: some View {
            content
                // Register with a parent BetterScrollViewProxy
                .preference(key: BetterScrollViewProxy.self, value: .init(scrollView: platformScrollView))
        }
    }
}

/// Equivalent of ``SwiftUI/ScrollViewReader``, but for ``BetterScrollView``.
struct BetterScrollViewReader<Content: View>: View {
    @ViewBuilder var content: (BetterScrollViewProxy) -> Content
    @State private var scrollProxy: BetterScrollViewProxy? = nil

    var body: some View {
        let proxy = scrollProxy ?? BetterScrollViewProxy(scrollView: nil)
        content(proxy)
            .onPreferenceChange(BetterScrollViewProxy.self) { newProxy in
                scrollProxy = newProxy
            }
    }
}

struct BetterScrollViewProxy: Equatable /* ugh, we're relying on NSScrollView.isEqual */ {
    /// The platform scroll view we want to control through this proxy.
    ///
    /// If this is `nil`, it means that no ``BetterScrollView`` exist in the view hierarchy below.
    /// In that case, all operations should be no-ops.
    ///
    /// I'd prefer to store the ``BetterScrollView.Coordinator`` instead of the NSScrollView,
    /// but that requires type erasure of the coordinator's generic parameters.
    fileprivate var scrollView: NSScrollView? = nil

    func scrollToBottom() {
        guard let scrollView,
              let documentView = scrollView.documentView
        else { return }
        let clipView = scrollView.contentView
        let bottomEdge = clipView.convert(NSPoint(x: 0, y: documentView.bounds.maxY), from: documentView).y
        // Calculate top edge of visible rect manually.
        // Using `scroll(to: … y: .greatestFiniteMagnitude)` like we do below did not work for me.
        let topVisibleEdge = bottomEdge - clipView.bounds.height
        clipView.scroll(to: NSPoint(x: clipView.bounds.minX, y: topVisibleEdge))
        // We must tell the containing scroll view to update its scroll bars.
        scrollView.reflectScrolledClipView(clipView)
    }
}

extension BetterScrollViewProxy: PreferenceKey {
    static var defaultValue: BetterScrollViewProxy? = nil

    static func reduce(value: inout BetterScrollViewProxy?, nextValue: () -> BetterScrollViewProxy?) {
        value = value ?? nextValue()
    }
}

extension NSClipView {
    var isScrolledToBottom: Bool {
        guard let documentView else { return false }
        
        let bottomEdge = convert(NSPoint(x: 0, y: documentView.bounds.maxY), from: documentView).y
        
        return bottomEdge - 0.1 <= bounds.maxY
    }
}
