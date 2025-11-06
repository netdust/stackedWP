// src/modules/image-scroll-effects.js

/**
 * Image Scroll Effects v3.0 – with horizontal scroll
 * ESM version for Vite
 */
class ImageScrollEffects {
    constructor(options = {}) {
        this.config = {
            selector: options.selector || '.image-scroll-effect',
            stickySelector: options.stickySelector || '.image-scroll-sticky',
            horizontalSelector: options.horizontalSelector || '.horizontal-scroll-section',
            lenis: options.lenis || null,
        };

        this.elements = [];
        this.stickyElements = [];
        this.horizontalElements = [];
        this.scrollHandler = null;

        this.init();
    }

    init() {
        console.log('Image Scroll Effects v3.0 initialized (with horizontal scroll)');
        this.findElements();
        this.setupScrollListener();
        this.animateImages();
    }

    findElements() {
        // Simple effects
        const elements = document.querySelectorAll(this.config.selector);
        this.elements = Array.from(elements).map(el => {
            el.classList.remove('active');
            return {
                element: el,
                effect: el.dataset.effect || 'fade',
                parallaxSpeed: parseFloat(el.dataset.parallaxSpeed || '0.5'),
            };
        });

        // Sticky effects
        const sticky = document.querySelectorAll(this.config.stickySelector);
        this.stickyElements = Array.from(sticky).map(el => ({
            element: el,
            content: el.querySelector('.image-scroll-sticky-content'),
            img: el.querySelector('img'),
            effect: el.dataset.effect || 'sticky-scale',
        }));

        // Horizontal scroll
        const horiz = document.querySelectorAll(this.config.horizontalSelector);
        this.horizontalElements = Array.from(horiz).map(el => ({
            element: el,
            track: el.querySelector('.horizontal-track'),
        }));

        console.log(
            `Found ${this.elements.length} images, ${this.stickyElements.length} sticky, ${this.horizontalElements.length} horizontal`
        );
    }

    setupScrollListener() {
        if (this.scrollHandler) return;

        this.scrollHandler = () => this.animateImages();

        if (this.config.lenis) {
            this.config.lenis.on('scroll', this.scrollHandler);
        } else {
            window.addEventListener('scroll', this.scrollHandler, { passive: true });
        }
    }

    removeScrollListener() {
        if (!this.scrollHandler) return;

        if (this.config.lenis) {
            this.config.lenis.off('scroll', this.scrollHandler);
        } else {
            window.removeEventListener('scroll', this.scrollHandler);
        }
        this.scrollHandler = null;
    }

    animateImages() {
        this.animateSimpleEffects();
        this.animateStickyEffects();
        this.animateHorizontalScroll();
    }

    animateSimpleEffects() {
        const vh = window.innerHeight;
        const centerY = vh / 2;

        this.elements.forEach(item => {
            const { element, effect, parallaxSpeed } = item;
            const rect = element.getBoundingClientRect();
            const elCenterY = rect.top + rect.height / 2;

            let progress = 0;
            if (elCenterY <= centerY) progress = 1;
            else if (elCenterY >= vh) progress = 0;
            else progress = (vh - elCenterY) / (vh - centerY);

            this.applyEffect(element, effect, progress, parallaxSpeed, rect, vh);
        });
    }

    applyEffect(element, effect, progress, parallaxSpeed, rect, vh) {
        const setStyle = (styles) => Object.assign(element.style, styles);
        const img = element.querySelector('img');

        switch (effect) {
            case 'fade':
                setStyle({ opacity: progress });
                break;
            case 'scale-up':
                setStyle({
                    opacity: progress,
                    transform: `scale(${0.8 + progress * 0.2})`,
                });
                break;
            case 'scale-down':
                setStyle({
                    opacity: progress,
                    transform: `scale(${1.2 - progress * 0.2})`,
                });
                break;
            case 'slide-up':
                setStyle({
                    opacity: progress,
                    transform: `translateY(${50 - progress * 50}px)`,
                });
                break;
            case 'slide-left':
                setStyle({
                    opacity: progress,
                    transform: `translateX(${50 - progress * 50}px)`,
                });
                break;
            case 'slide-right':
                setStyle({
                    opacity: progress,
                    transform: `translateX(${-50 + progress * 50}px)`,
                });
                break;
            case 'blur':
                setStyle({
                    filter: `blur(${10 - progress * 10}px)`,
                    opacity: 0.5 + progress * 0.5,
                });
                break;
            case 'rotate':
                setStyle({
                    opacity: progress,
                    transform: `rotate(${-10 + progress * 10}deg) scale(${0.9 + progress * 0.1})`,
                });
                break;
            case 'parallax':
                if (img) {
                    const elCenterY = rect.top + rect.height / 2;
                    const parallaxProgress = (vh - elCenterY) / (vh + rect.height);
                    const movement = (parallaxProgress - 0.5) * 100 * parallaxSpeed;
                    img.style.transform = `translateY(${movement}px)`;
                }
                break;
            case 'clip-up':
                if (img) img.style.clipPath = `inset(${(1 - progress) * 100}% 0 0 0)`;
                break;
            case 'clip-right':
                if (img) img.style.clipPath = `inset(0 ${(1 - progress) * 100}% 0 0)`;
                break;
            case 'clip-left':
                if (img) img.style.clipPath = `inset(0 0 0 ${(1 - progress) * 100}%)`;
                break;
            case 'ken-burns':
                setStyle({ opacity: progress });
                if (img) img.style.transform = `scale(${1 + progress * 0.1})`;
                break;
        }
    }

    animateStickyEffects() {
        const vh = window.innerHeight;

        this.stickyElements.forEach(item => {
            const { element, img, effect } = item;
            if (!img) return;

            const rect = element.getBoundingClientRect();
            const progress = Math.max(0, Math.min(1, (vh - rect.top) / (vh + rect.height)));

            const setImgStyle = (styles) => Object.assign(img.style, styles);

            switch (effect) {
                case 'sticky-slide-left':
                    setImgStyle({ transform: `translateX(${(1 - progress) * 100}%)` });
                    break;
                case 'sticky-slide-right':
                    setImgStyle({ transform: `translateX(${(progress - 1) * 100}%)` });
                    break;
                case 'sticky-scale':
                    setImgStyle({ transform: `scale(${0.5 + progress * 0.5})` });
                    break;
                case 'sticky-clip':
                    setImgStyle({ clipPath: `inset(0 ${(1 - progress) * 100}% 0 0)` });
                    break;
                case 'sticky-rotate':
                    setImgStyle({
                        transform: `rotate(${-45 + progress * 45}deg) scale(${0.7 + progress * 0.3})`,
                    });
                    break;
            }
        });
    }

    animateHorizontalScroll() {
        const vh = window.innerHeight;

        this.horizontalElements.forEach(item => {
            const { element, track } = item;
            if (!track) return;

            const rect = element.getBoundingClientRect();
            const progress = Math.max(0, Math.min(1, (vh - rect.top) / (vh + rect.height)));
            const trackWidth = track.scrollWidth;
            const containerWidth = element.offsetWidth;
            const maxTranslate = trackWidth - containerWidth;
            const translateX = -(progress * maxTranslate);

            track.style.transform = `translateX(${translateX}px)`;
        });
    }

    refresh() {
        this.elements.forEach(item => item.element.classList.remove('active'));
        this.elements = [];
        this.stickyElements = [];
        this.horizontalElements = [];
        this.findElements();
        this.animateImages();
        console.log('Image scroll effects refreshed');
    }

    destroy() {
        this.removeScrollListener();
        this.elements = [];
        this.stickyElements = [];
        this.horizontalElements = [];
    }
}

// Export factory
export const imageScroll = {
    init: (options) => new ImageScrollEffects(options),
    version: '3.0.0',
};

// Optional: expose globally for legacy
if (typeof window !== 'undefined') {
    window.ntdst = window.ntdst || {};
    window.ntdst.imageScroll = imageScroll;
}