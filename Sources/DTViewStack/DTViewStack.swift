import MapKit
import SwiftUI
import DTRoundedCorners

/*
 ----------------------
 |                      |
 |                      | -> Map()
 |                      |
 |----------------------| -> viewOffset
 |                      |   |
 |                      |   |
 |                      |   -> viewFingerDiff
 |                      |   |
 |                      |   |
 |           *          | -> fingerOffset
 |                      |
 ----------------------
 */

// MARK: - Main view
public struct DTViewStack<Primary: View, Secondary: View, Toolbar: View>: View {
    
    // MARK: Properties
    let geo: GeometryProxy
    let primary: () -> Primary
    let secondary: () -> Secondary
    let toolbar: () -> Toolbar
    
    private let geoFrame: CGRect
    private let nestedViewMinY: CGFloat
    private let nestedViewMaxY: CGFloat
    
    private var nestedViewMidY: CGFloat {
        0.60 * geoFrame.maxY
    }
    
    // MARK: State
    @State private var viewOffset: CGFloat
    @State private var viewFingerDiff: CGFloat = 0
    @State private var isDragging = false
    
    // MARK: Bindings
    @Binding var searchableText: String?
    @Binding var presenterReceiver: Bool?
    
    // MARK: Init
    public init(
        geo: GeometryProxy,
        searchableText: Binding<String?>? = nil,
        presenterReceiver: Binding<Bool?>? = nil,
        @ViewBuilder primary: @escaping () -> Primary,
        @ViewBuilder secondary: @escaping () -> Secondary,
        @ViewBuilder toolbar: @escaping () -> Toolbar
    ) {
        self.geo = geo
        self._searchableText = searchableText ?? Binding.constant(nil)
        self._presenterReceiver = presenterReceiver ?? Binding.constant(nil)
        self.primary = primary
        self.secondary = secondary
        self.toolbar = toolbar
        self.geoFrame = geo.frame(in: .local)
        self.nestedViewMinY = geoFrame.maxY * 0.05
        self.nestedViewMaxY = geoFrame.maxY * 0.73
        self._viewOffset = State(initialValue: nestedViewMaxY)
        
    }
    
    // MARK: Actions
    func drag(with fingerOffset: CGFloat) {
        if !isDragging {
            
            // First drag -> lock viewFingerDiff
            viewFingerDiff = viewOffset - fingerOffset
        }
        
        let viewFutureOffset = viewFingerDiff + fingerOffset
        
        // If nested view is between bounds -> allow movement
        if viewFutureOffset >= nestedViewMinY && viewFutureOffset <= nestedViewMaxY {
            viewOffset = viewFutureOffset
        }
        
        isDragging = true
    }
    
    func moveOnEndedDrag() {
        let pctViewOffset = viewOffset / geoFrame.maxY
        
        switch pctViewOffset {
        case 0.7...1.0:
            viewOffset = nestedViewMaxY
        case 0.25...0.7:
            viewOffset = nestedViewMidY
        case 0.0...0.25:
            viewOffset = nestedViewMinY
        default:
            viewOffset = nestedViewMinY
        }
    }
    
    // MARK: Body
    public var body: some View {
        ZStack(alignment: .bottom) {
            primary()
            
            VStack {
                toolbar()
                    .offset(y: viewOffset)
                
                SecondaryView(content: secondary)
                    .offset(y: viewOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                drag(with: value.location.y)
                            }
                            .onEnded { _ in
                                isDragging = false
                                
                                withAnimation {
                                    moveOnEndedDrag()
                                }
                            }
                    )
                    .onChange(of: presenterReceiver) { newValue in
                        if let present = newValue {
                            withAnimation(.easeOut(duration: 0.3)) {
                                if present == true {
                                    viewOffset = nestedViewMinY
                                } else {
                                    viewOffset = nestedViewMaxY
                                }
                            }
                        }
                        
                        presenterReceiver = nil
                    }
            }
        }
    }
}

struct SecondaryView<Content: View>: View {
    
    // MARK: Properties
    let content: () -> Content
    
    var body: some View {
        content()
            .background {
                Rectangle()
                    .foregroundStyle(.thinMaterial)
                    .roundCorners(20, corners: [.topLeft, .topRight])
            }
            .scrollContentBackground(.hidden)
    }
}
