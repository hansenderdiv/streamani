import Foundation
import WebKit
import Combine

// MARK: - Stream Sniffer Delegate

protocol StreamSnifferDelegate: AnyObject {
    func streamSniffer(_ sniffer: StreamSniffer, didFindStreamURL url: URL)
    func streamSniffer(_ sniffer: StreamSniffer, didFailWithError error: String)
}

// MARK: - Stream Sniffer

/// A WKWebView-based link sniffer that loads a streaming provider page,
/// injects JavaScript to monitor network requests and HTML5 <video> elements,
/// and extracts the direct .m3u8 (HLS) or .mp4 stream URL.
final class StreamSniffer: NSObject {
    
    weak var delegate: StreamSnifferDelegate?
    
    private(set) var webView: WKWebView
    private var sniffTimer: Timer?
    private var hasFoundStream = false
    private let maxWaitTime: TimeInterval = 20.0
    
    // MARK: - JavaScript Injection Script
    
    /// This script monitors:
    /// 1. The HTML5 <video> src attribute
    /// 2. XMLHttpRequest and fetch() calls for .m3u8/.mp4 URLs
    /// 3. HLS.js / video.js source loading
    private static let snifferScript = """
    (function() {
        'use strict';
        
        // Prevent double-injection
        if (window.__aniStreamSnifferActive) return;
        window.__aniStreamSnifferActive = true;
        
        const STREAM_EXTENSIONS = ['.m3u8', '.mp4', '.webm', '.ts'];
        const STREAM_PATTERNS = [
            /\\.m3u8(\\?|$)/i,
            /\\.mp4(\\?|$)/i,
            /\\.webm(\\?|$)/i,
            /master\\.m3u8/i,
            /playlist\\.m3u8/i,
            /index\\.m3u8/i,
            /hls\\//i,
            /stream\\//i
        ];
        
        function isStreamURL(url) {
            if (!url || typeof url !== 'string') return false;
            return STREAM_PATTERNS.some(p => p.test(url));
        }
        
        function reportURL(url) {
            if (!url || typeof url !== 'string') return;
            // Clean the URL
            try {
                const parsed = new URL(url, window.location.href);
                const clean = parsed.href;
                if (isStreamURL(clean)) {
                    window.webkit.messageHandlers.streamSniffer.postMessage({
                        type: 'streamFound',
                        url: clean
                    });
                }
            } catch(e) {}
        }
        
        // --- 1. Monitor <video> elements ---
        function checkVideoElements() {
            const videos = document.querySelectorAll('video');
            videos.forEach(function(video) {
                if (video.src && isStreamURL(video.src)) {
                    reportURL(video.src);
                }
                const sources = video.querySelectorAll('source');
                sources.forEach(function(source) {
                    if (source.src && isStreamURL(source.src)) {
                        reportURL(source.src);
                    }
                });
                // Monitor src changes
                if (!video.__aniStreamObserved) {
                    video.__aniStreamObserved = true;
                    const observer = new MutationObserver(function(mutations) {
                        mutations.forEach(function(m) {
                            if (m.attributeName === 'src' && video.src) {
                                reportURL(video.src);
                            }
                        });
                    });
                    observer.observe(video, { attributes: true });
                }
            });
        }
        
        // --- 2. Intercept XMLHttpRequest ---
        const OrigXHR = window.XMLHttpRequest;
        function PatchedXHR() {
            const xhr = new OrigXHR();
            const origOpen = xhr.open.bind(xhr);
            xhr.open = function(method, url, ...args) {
                reportURL(url);
                return origOpen(method, url, ...args);
            };
            return xhr;
        }
        PatchedXHR.prototype = OrigXHR.prototype;
        window.XMLHttpRequest = PatchedXHR;
        
        // --- 3. Intercept fetch() ---
        const origFetch = window.fetch;
        window.fetch = function(input, init) {
            const url = typeof input === 'string' ? input : (input && input.url);
            if (url) reportURL(url);
            return origFetch.apply(this, arguments);
        };
        
        // --- 4. Intercept MediaSource / SourceBuffer ---
        if (window.MediaSource) {
            const origAddSourceBuffer = MediaSource.prototype.addSourceBuffer;
            MediaSource.prototype.addSourceBuffer = function(mimeType) {
                window.webkit.messageHandlers.streamSniffer.postMessage({
                    type: 'mediaSource',
                    mimeType: mimeType
                });
                return origAddSourceBuffer.apply(this, arguments);
            };
        }
        
        // --- 5. Intercept HLS.js loadSource ---
        const origDefineProperty = Object.defineProperty;
        
        // --- 6. Monitor DOM for new video elements ---
        const domObserver = new MutationObserver(function() {
            checkVideoElements();
        });
        domObserver.observe(document.documentElement, {
            childList: true,
            subtree: true
        });
        
        // Initial check
        checkVideoElements();
        
        // Periodic check
        setInterval(checkVideoElements, 500);
        
        // Signal ready
        window.webkit.messageHandlers.streamSniffer.postMessage({
            type: 'ready'
        });
        
    })();
    """
    
    // MARK: - Initialization
    
    override init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Allow all content
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences
        
        // User content controller for JS message handling
        let userContentController = WKUserContentController()
        
        // Inject sniffer script at document start
        let userScript = WKUserScript(
            source: StreamSniffer.snifferScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        userContentController.addUserScript(userScript)
        config.userContentController = userContentController
        
        // Create WebView
        webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
        super.init()
        
        // Register message handler
        userContentController.add(self, name: "streamSniffer")
        webView.navigationDelegate = self
    }
    
    // MARK: - Public Methods
    
    func sniff(url: URL) {
        hasFoundStream = false
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        webView.load(request)
        
        // Start timeout timer
        sniffTimer = Timer.scheduledTimer(withTimeInterval: maxWaitTime, repeats: false) { [weak self] _ in
            guard let self = self, !self.hasFoundStream else { return }
            self.delegate?.streamSniffer(self, didFailWithError: "Stream-URL konnte nicht gefunden werden (Timeout)")
        }
    }
    
    func stop() {
        sniffTimer?.invalidate()
        sniffTimer = nil
        webView.stopLoading()
    }
    
    deinit {
        stop()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "streamSniffer")
    }
}

// MARK: - WKScriptMessageHandler

extension StreamSniffer: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                                didReceive message: WKScriptMessage) {
        guard !hasFoundStream,
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }
        
        switch type {
        case "streamFound":
            if let urlString = body["url"] as? String,
               let url = URL(string: urlString) {
                hasFoundStream = true
                sniffTimer?.invalidate()
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.streamSniffer(self, didFindStreamURL: url)
                }
            }
            
        case "ready":
            // Script injected successfully, inject additional provider-specific scripts
            injectProviderSpecificScript()
            
        default:
            break
        }
    }
    
    /// Inject provider-specific extraction logic after page loads
    private func injectProviderSpecificScript() {
        let providerScript = """
        (function() {
            // VOE.sx specific extraction
            if (window.location.hostname.includes('voe.sx') || window.location.hostname.includes('voe.')) {
                // VOE stores the stream in a variable called 'sources' or 'hls'
                setTimeout(function() {
                    try {
                        if (typeof sources !== 'undefined') {
                            const src = sources.hls || sources.mp4 || sources[0];
                            if (src) {
                                window.webkit.messageHandlers.streamSniffer.postMessage({
                                    type: 'streamFound', url: src
                                });
                            }
                        }
                    } catch(e) {}
                }, 2000);
            }
            
            // Vidmoly specific extraction
            if (window.location.hostname.includes('vidmoly')) {
                setTimeout(function() {
                    try {
                        const scripts = document.querySelectorAll('script');
                        scripts.forEach(function(s) {
                            const m = s.textContent.match(/file:\\s*["']([^"']+\\.m3u8[^"']*)/);
                            if (m) {
                                window.webkit.messageHandlers.streamSniffer.postMessage({
                                    type: 'streamFound', url: m[1]
                                });
                            }
                        });
                    } catch(e) {}
                }, 2000);
            }
            
            // Vidoza specific extraction
            if (window.location.hostname.includes('vidoza')) {
                setTimeout(function() {
                    try {
                        const scripts = document.querySelectorAll('script');
                        scripts.forEach(function(s) {
                            const m = s.textContent.match(/sourcesCode:\\s*\\[\\{src:\\s*["']([^"']+)/);
                            if (m) {
                                window.webkit.messageHandlers.streamSniffer.postMessage({
                                    type: 'streamFound', url: m[1]
                                });
                            }
                        });
                    } catch(e) {}
                }, 2000);
            }
            
            // Generic: scan all script tags for m3u8 URLs
            setTimeout(function() {
                const scripts = document.querySelectorAll('script');
                const m3u8Pattern = /https?:\\/\\/[^"'\\s]+\\.m3u8[^"'\\s]*/g;
                scripts.forEach(function(s) {
                    const matches = s.textContent.match(m3u8Pattern);
                    if (matches && matches.length > 0) {
                        window.webkit.messageHandlers.streamSniffer.postMessage({
                            type: 'streamFound', url: matches[0]
                        });
                    }
                });
            }, 3000);
        })();
        """
        
        webView.evaluateJavaScript(providerScript, completionHandler: nil)
    }
}

// MARK: - WKNavigationDelegate

extension StreamSniffer: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Re-inject sniffer on navigation
        webView.evaluateJavaScript(StreamSniffer.snifferScript, completionHandler: nil)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard !hasFoundStream else { return }
        // Don't fail on minor navigation errors
        print("WebView navigation error: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Block known ad/tracker domains
        if let host = navigationAction.request.url?.host {
            let blockedDomains = ["doubleclick.net", "googlesyndication.com", "adnxs.com",
                                  "adsystem.com", "amazon-adsystem.com", "googletagmanager.com"]
            if blockedDomains.contains(where: { host.contains($0) }) {
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}
