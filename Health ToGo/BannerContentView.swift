// Supporto per integrare gli Ads di Google

import GoogleMobileAds
import SwiftUI

struct BannerContentView: View {
    var body: some View {
        GeometryReader { geometry in
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: geometry.size.width)
            
            VStack {
                Spacer()
                BannerViewContainer(adSize)
                    .frame(height: adSize.size.height)
            }
        }
    }
}

// [START create_banner_view]
private struct BannerViewContainer: UIViewRepresentable {
    let adSize: AdSize
    
    init(_ adSize: AdSize) {
        self.adSize = adSize
    }
    
    func makeUIView(context: Context) -> UIView {
        // Wrap the GADBannerView in a UIView. GADBannerView automatically reloads a new ad when its
        // frame size changes; wrapping in a UIView container insulates the GADBannerView from size
        // changes that impact the view returned from makeUIView.
        let view = UIView()
        view.addSubview(context.coordinator.bannerView)
        return view
    }
    
    func updateUIView(_: UIView, context: Context) {
        context.coordinator.bannerView.adSize = adSize
    }
    
    func makeCoordinator() -> BannerCoordinator {
        return BannerCoordinator(self)
    }
    // [END create_banner_view]
    
    // [START create_banner]
    class BannerCoordinator: NSObject, BannerViewDelegate {
        
        private(set) lazy var bannerView: BannerView = {
            let banner = BannerView(adSize: parent.adSize)
            
            // [START load_ad]
#if DEBUG
            print("DEBUG MODE - using Test ID")
            banner.adUnitID = "ca-app-pub-3940256099942544/2435281174" // Test ID
#else
            print("RELEASE MODE - Using Prod ID")
            banner.adUnitID = "ca-app-pub-2391738721011118/7174690469" // Real ID
#endif
            
            banner.load(Request())
            // [END load_ad]
            
            // [START set_delegate]
            banner.delegate = self
            // [END set_delegate]
            return banner
        }()
        
        let parent: BannerViewContainer
        
        init(_ parent: BannerViewContainer) {
            self.parent = parent
        }
        // [END create_banner]
        
        // - GADBannerViewDelegate methods
        func bannerViewDidReceiveAd(_: BannerView) {
            print("DID RECEIVE AD.")
        }
        
        func bannerView(_: BannerView, didFailToReceiveAdWithError error: Error) {
            print("FAILED TO RECEIVE AD: \(error.localizedDescription)")
        }
    }
}
