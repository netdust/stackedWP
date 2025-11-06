// src/modules/barba.js
import barba from '@barba/core';

/**
 * Netdust Barba.js – Clean ESM Module
 */
class NetdustBarba {
    constructor() {
        this.config = {
            transitionName: 'simple-transition',
            animationDuration: 500,
            overlaySelectors: {
                top: '.overlay-top',
                bottom: '.overlay-bottom',
            },
            preventSelectors: [
                '[href*="wp-admin"]',
                '[target="_blank"]',
                '.no-barba',
                '[href^="#"]',
            ],
        };

        this.state = {
            initialized: false,
            transitioning: false,
            currentContainer: null,
            animator: null,
        };

        this.animator = null;
    }

    // --- Public API ---

    async init(options = {}) {
        if (this.state.initialized) return false;

        if (!document.querySelector('[data-barba="wrapper"]') || !document.querySelector('[data-barba="container"]')) {
            console.error('Barba: Missing required HTML structure!', {
                wrapper: '[data-barba="wrapper"]',
                container: '[data-barba="container"]',
            });
            return false;
        }

        Object.assign(this.config, options);
        this.animator = options.animator || new BarbaAnimator(this.config);

        this.initBarba();
        this.state.initialized = true;

        console.log('Netdust Barba.js initialized');
        return this;
    }

    destroy() {
        if (barba && barba.destroy) {
            barba.destroy();
            this.state.initialized = false;
            console.log('Barba.js destroyed');
        }
    }

    navigateTo(url) {
        if (this.state.transitioning) return false;
        barba.go(url);
        return true;
    }

    isTransitioning() {
        return this.state.transitioning;
    }

    updateConfig(newConfig) {
        Object.assign(this.config, newConfig);
    }

    getState() {
        return { ...this.state };
    }

    // --- Private ---

    initBarba() {
        const self = this;

        barba.init({
            debug: true,
            transitions: [{
                name: self.config.transitionName,

                async once({ next }) {
                    await self.handleOnce(next);
                },

                async leave({ current }) {
                    await self.handleLeave(current);
                },

                async enter({ next }) {
                    await self.handleEnter(next);
                },
            }],

            prevent: ({ el, event }) => {
                if (!el.href || el.href === window.location.href) {
                    event.preventDefault();
                    event.stopPropagation();
                    return true;
                }
                return self.shouldPrevent(el);
            },
        });

        console.log('Barba initialized with debug mode');
    }

    shouldPrevent(el) {
        return this.config.preventSelectors.some(sel => {
            if (sel.includes('*')) {
                const pattern = sel.replace('[href*="', '').replace('"]', '');
                return el.href.includes(pattern);
            }
            return el.matches(sel);
        });
    }

    updateBodyClasses(next) {
        const parser = new DOMParser();
        const doc = parser.parseFromString(next.html, 'text/html');
        const classes = doc.body.getAttribute('class');
        if (classes !== null) {
            document.body.setAttribute('class', classes);
        }
    }

    async handleOnce(next) {
        if (!next.container) return;
        next.container.style.opacity = '0';
        await this.animator.in(next.container);
        this.dispatch('barba:after', { next });
    }

    async handleLeave(current) {
        this.state.transitioning = true;
        this.state.currentContainer = current.container;

        if (current.container) {
            current.container.style.opacity = '0';
            current.container.style.display = 'none';
            current.container.style.visibility = 'hidden';
            await this.animator.out(current.container);
            current.container.remove();
        }
    }

    async handleEnter(next) {
        if (next.container) {
            next.container.style.opacity = '0';
            await this.animator.in(next.container);
        }
        this.state.transitioning = false;
        this.dispatch('barba:after', { next });
    }

    dispatch(eventName, detail) {
        document.dispatchEvent(new CustomEvent(eventName, { detail }));
    }
}

// --- Animator (can be overridden) ---
class BarbaAnimator {
    constructor(config) {
        this.duration = config.animationDuration || 500;
    }

    async in(el) {
        el.style.transition = `opacity ${this.duration}ms ease`;
        await new Promise(r => setTimeout(r, 50));
        el.style.opacity = '1';
        return new Promise(r => setTimeout(r, this.duration));
    }

    async out(el) {
        el.style.transition = `opacity ${this.duration}ms ease`;
        el.style.opacity = '0';
        return new Promise(r => setTimeout(r, this.duration));
    }
}

// --- Export ---
export const barbajs = new NetdustBarba();

// Optional: expose globally for legacy
if (typeof window !== 'undefined') {
    window.ntdst = window.ntdst || {};
    window.ntdst.barbajs = barbajs;

    // Global helpers
    window.ntdstNavigateTo = (url) => barbajs.navigateTo(url);
    window.ntdstIsTransitioning = () => barbajs.isTransitioning();
}