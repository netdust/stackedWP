// src/modules/scroll-effects.js
import { imageScroll } from './image-scroll.js';
import { textScroll } from './text-scroll.js';
import Lenis from 'lenis';


let lenis = null;
let textScrollInstance = null;
let imageScrollInstance = null;
let rafId = null;

/**
 * Initialize Lenis + scroll-based effects
 */
export function initScrollEffects() {
    if (lenis) {
        console.warn('[ScrollEffects] Already initialized');
        return;
    }

    // Initialize Lenis
    lenis = new Lenis({
        duration: 1.2,
        easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
        smoothWheel: true,
    });

    // RAF loop
    const raf = (time) => {
        lenis?.raf(time);
        rafId = requestAnimationFrame(raf);
    };
    rafId = requestAnimationFrame(raf);

    // Initialize text scroll effects (via ESM import)
    textScrollInstance = textScroll.init({ lenis });

    // Initialize image scroll effects (via ESM import)
    imageScrollInstance = imageScroll.init({ lenis });

    console.log('[ScrollEffects] Initialized');
}

/**
 * Destroy all scroll effects
 */
export function destroyScrollEffects() {
    if (rafId) {
        cancelAnimationFrame(rafId);
        rafId = null;
    }

    lenis?.destroy();
    lenis = null;

    if (textScrollInstance?.destroy) textScrollInstance.destroy();
    textScrollInstance = null;

    if (imageScrollInstance?.destroy) imageScrollInstance.destroy();
    imageScrollInstance = null;

    console.log('[ScrollEffects] Destroyed');
}

/**
 * Scroll to top
 */
export function scrollToTop(instant = false) {
    if (lenis) {
        lenis.scrollTo(0, { immediate: instant });
    } else {
        window.scrollTo(0, 0);
    }
}

/**
 * Get Lenis instance
 */
export const getLenis = () => lenis;

// Optional: expose globally for legacy
if (typeof window !== 'undefined') {
    window.ntdst = window.ntdst || {};

    // Global helpers
    window.ntdst.scrollToTop = (instant) => scrollToTop(instant);
    window.ntdst.getLenis = () => getLenis();
}