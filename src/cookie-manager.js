// Clean Netdust Cookie Manager - Dual Use (Vite + WordPress)
((factory) => {
    // Dual export pattern
    if (typeof module !== 'undefined' && module.exports) module.exports = factory();
    if (typeof window !== 'undefined') {
        window.ntdst = window.ntdst || {};
        window.ntdst.cookieManager = factory();
    }
})(() => {

    const $ = (typeof window !== 'undefined' && window.UIkit) ? window.UIkit.util : null;

    return {
        // Configuration
        config: {
            cookieName: 'ntdst_cookie_consent',
            cookiePrefs: 'ntdst_cookie_preferences',
            cookieExpiry: 365,
            categories: {
                necessary: true,
                analytics: false,
                marketing: false,
                functional: false
            },
            scripts: {
                analytics: {
                    ga4: 'G-XXXXXXXXXX',
                    gtm: 'GTM-XXXXXXX'
                },
                marketing: {
                    fbPixel: 'YOUR_PIXEL_ID',
                    linkedIn: 'YOUR_PARTNER_ID'
                }
            }
        },

        // State
        state: {
            initialized: false,
            consentGiven: false,
            scriptsLoaded: []
        },

        // Initialize
        init(options = {}) {
            if (this.state.initialized || !$) return false;

            Object.assign(this.config, options);
            this.setupGlobals();
            this.checkExistingConsent();
            this.bindEvents();
            this.state.initialized = true;

            console.log('🍪 Netdust Cookie Manager initialized');
            return this;
        },

        // Setup global functions
        setupGlobals() {
            window.ntdstTrack = this.track.bind(this);
            window.ntdstConsent = this.grantConsent.bind(this);
            window.ntdstRevoke = this.revokeConsent.bind(this);
            window.dataLayer = window.dataLayer || [];
            window.gtag = window.gtag || function() { dataLayer.push(arguments); };
        },

        // Event binding
        bindEvents() {
            // YOOtheme cookie banner
            $.on(document, 'click', '.tm-cookie-banner .js-accept', () => {
                console.log('🍪 YOOtheme consent granted');
                this.handleYOOthemeConsent();
            });

            $.on(document, 'click', '.tm-cookie-banner .js-reject', () => {
                console.log('🍪 YOOtheme consent declined');
                this.handleYOOthemeDecline();
            });

            // Custom consent events
            $.on(document, 'ntdst:consent:granted', (e) => {
                this.grantConsent(e.detail);
            });

            $.on(document, 'ntdst:consent:revoked', () => {
                this.revokeConsent();
            });
        },

        // Check existing consent
        checkExistingConsent() {
            const consent = this.getCookie(this.config.cookieName);
            const preferences = this.getCookie(this.config.cookiePrefs);

            if (consent === 'true' && preferences) {
                console.log('🍪 Existing consent found');
                this.config.categories = JSON.parse(preferences);
                this.state.consentGiven = true;
                this.loadConsentScripts();
            }
        },

        // YOOtheme handlers
        handleYOOthemeConsent() {
            this.grantConsent({
                necessary: true,
                analytics: true,
                marketing: true,
                functional: true
            });
        },

        handleYOOthemeDecline() {
            this.grantConsent({
                necessary: true,
                analytics: false,
                marketing: false,
                functional: false
            });
        },

        // Grant consent
        grantConsent(categories = {}) {
            Object.assign(this.config.categories, categories);

            this.setCookie(this.config.cookieName, 'true', this.config.cookieExpiry);
            this.setCookie(this.config.cookiePrefs, JSON.stringify(this.config.categories), this.config.cookieExpiry);

            this.state.consentGiven = true;
            this.loadConsentScripts();

            $.trigger(document, 'ntdst:consent:updated', this.config.categories);
            console.log('🍪 Consent granted:', this.config.categories);
        },

        // Revoke consent
        revokeConsent() {
            this.config.categories = {
                necessary: true,
                analytics: false,
                marketing: false,
                functional: false
            };

            this.deleteCookie(this.config.cookieName);
            this.deleteCookie(this.config.cookiePrefs);
            this.state.consentGiven = false;
            this.state.scriptsLoaded = [];

            $.trigger(document, 'ntdst:consent:revoked');
            console.log('🍪 Consent revoked');
        },

        // Load consent-based scripts
        loadConsentScripts() {
            if (this.config.categories.analytics) this.loadAnalyticsScripts();
            if (this.config.categories.marketing) this.loadMarketingScripts();
            if (this.config.categories.functional) this.loadFunctionalScripts();
        },

        // Analytics scripts
        loadAnalyticsScripts() {
            if (this.state.scriptsLoaded.includes('analytics')) return;

            console.log('📊 Loading analytics scripts');

            if (this.config.scripts.analytics.ga4) {
                this.loadGA4(this.config.scripts.analytics.ga4);
            }

            if (this.config.scripts.analytics.gtm) {
                this.loadGTM(this.config.scripts.analytics.gtm);
            }

            this.state.scriptsLoaded.push('analytics');
        },

        // Marketing scripts
        loadMarketingScripts() {
            if (this.state.scriptsLoaded.includes('marketing')) return;

            console.log('📢 Loading marketing scripts');

            if (this.config.scripts.marketing.fbPixel) {
                this.loadFacebookPixel(this.config.scripts.marketing.fbPixel);
            }

            this.state.scriptsLoaded.push('marketing');
        },

        // Functional scripts
        loadFunctionalScripts() {
            if (this.state.scriptsLoaded.includes('functional')) return;

            console.log('⚙️ Loading functional scripts');
            // Add functional scripts here (chat widgets, etc.)

            this.state.scriptsLoaded.push('functional');
        },

        // Load GA4
        loadGA4(measurementId) {
            const script = document.createElement('script');
            script.async = true;
            script.src = `https://www.googletagmanager.com/gtag/js?id=${measurementId}`;
            document.head.appendChild(script);

            script.onload = () => {
                gtag('js', new Date());
                gtag('config', measurementId, {
                    anonymize_ip: true,
                    allow_google_signals: false
                });
                console.log('✅ GA4 loaded:', measurementId);
            };
        },

        // Load GTM
        loadGTM(gtmId) {
            (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
                    new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
                j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
                'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
            })(window,document,'script','dataLayer', gtmId);

            dataLayer.push({
                'event': 'consent_update',
                'consent_analytics': this.config.categories.analytics,
                'consent_marketing': this.config.categories.marketing
            });

            console.log('✅ GTM loaded:', gtmId);
        },

        // Load Facebook Pixel
        loadFacebookPixel(pixelId) {
            !function(f,b,e,v,n,t,s)
            {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
                n.callMethod.apply(n,arguments):n.queue.push(arguments)};
                if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
                n.queue=[];t=b.createElement(e);t.async=!0;
                t.src=v;s=b.getElementsByTagName(e)[0];
                s.parentNode.insertBefore(t,s)}(window, document,'script',
                'https://connect.facebook.net/en_US/fbevents.js');

            fbq('init', pixelId);
            fbq('track', 'PageView');
            console.log('✅ Facebook Pixel loaded:', pixelId);
        },

        // Track events
        track(event, data = {}) {
            if (!this.config.categories.analytics) {
                console.log('🚫 Tracking blocked - no analytics consent');
                return false;
            }

            // Send to GA4
            if (typeof gtag !== 'undefined') {
                gtag('event', event, data);
            }

            // Send to GTM dataLayer
            if (typeof dataLayer !== 'undefined') {
                dataLayer.push({
                    'event': event,
                    ...data
                });
            }

            console.log('📊 Event tracked:', event, data);
            return true;
        },

        // Cookie utilities
        getCookie(name) {
            const value = `; ${document.cookie}`;
            const parts = value.split(`; ${name}=`);
            if (parts.length === 2) return parts.pop().split(';').shift();
        },

        setCookie(name, value, days) {
            const expires = new Date(Date.now() + days * 864e5).toUTCString();
            document.cookie = `${name}=${value}; expires=${expires}; path=/; secure; samesite=strict`;
        },

        deleteCookie(name) {
            document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
        },

        // Public API
        hasConsent(category) {
            return this.config.categories[category] || false;
        },

        getConsentStatus() {
            return { ...this.config.categories };
        },

        isInitialized() {
            return this.state.initialized;
        },

        updateConfig(newConfig) {
            Object.assign(this.config, newConfig);
            console.log('🍪 Configuration updated');
        }
    };
});

// Global helpers and auto-init (WordPress compatibility)
if (typeof window !== 'undefined') {
    // Global convenience functions
    window.ntdstHasConsent = (category) => window.ntdst?.cookieManager?.hasConsent(category);
    window.ntdstGetConsent = () => window.ntdst?.cookieManager?.getConsentStatus();

    // Auto-init when ready
    if (window.UIkit?.util?.ready) {
        window.UIkit.util.ready(() => {
            // Use localized config from WordPress if available
            const config = typeof netdustCookieConfig !== 'undefined' ? netdustCookieConfig : {};
            window.ntdst.cookieManager.init(config);
        });
    }
}