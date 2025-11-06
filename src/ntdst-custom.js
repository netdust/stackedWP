// src/main.js
/* --------------------------------------------------------------
   MAIN ENTRY POINT – Vite + Barba + Lenis + UIkit + TriangleHero
   -------------------------------------------------------------- */

import { initScrollEffects, destroyScrollEffects, scrollToTop, getLenis } from './effects/scroll-effects.js';
import { BarbaAnimation } from './barba-animations.js';
import { triangleHero } from './triangle-hero.js';
import { barbajs } from './barba.js';
import barba from '@barba/core';


const waitForDom = () =>
    document.readyState === 'loading'
        ? new Promise(resolve => document.addEventListener('DOMContentLoaded', resolve))
        : Promise.resolve();

const initUIKit = async () => {
    await waitForDom();

    const modalEl = document.getElementById('tm-dialog'); // <-- note: **no** leading '#'
    if (modalEl && typeof UIkit !== 'undefined') {
        UIkit.modal(modalEl, { animation: false });
    }
};

const initBarba = async () => {
    await waitForDom();

    // ---- Guard: Barba must be available --------------------------------
    if (typeof barba === 'undefined') {
        console.warn('Barba.js not loaded – page transitions disabled');
        return;
    }

    // ---- Barba hooks ---------------------------------------------------
    barba.hooks.beforeLeave(() => {
        destroyScrollEffects();                     // stop Lenis + scroll effects
        UIkit.offcanvas('#tm-dialog')?.hide();      // close any open off-canvas
    });

    barba.hooks.beforeEnter(() => {
        // Remove duplicate modals that may have been cloned by WordPress
        const modals = document.querySelectorAll('#tm-dialog');
        modals.forEach((el, i) => i > 0 && el.remove());
    });

    barba.hooks.afterEnter(() => {
        scrollToTop(false);                         // smooth scroll to top

        const lenis = getLenis();
        lenis?.resize();                            // recalc after new content

        initScrollEffects();                        // re-init Lenis + image/text effects
        triangleHero.reinit();                      // re-run triangle hero

        if ( typeof UIkit !== 'undefined') {
            UIkit.update();
        }
    });

    // ---- Custom animator ------------------------------------------------
    const animator = new BarbaAnimation({
        animationDuration: 500,
        overlaySelectors: { top: '.overlay-top', bottom: '.overlay-bottom' },
    });

    // ---- Initialise Barba ------------------------------------------------
    try {
        await barbajs.init({ animator });
        console.log('Barba.js ready');
    } catch (err) {
        console.error('Barba init failed:', err);
    }
};


(async () => {
    // 1. UIkit first – it may be needed by the markup
    await initUIKit();

    // 2. Initialise scroll effects (Lenis) on the **first** page load
    initScrollEffects();

    // 3. Initialise Barba (handles all future page changes)
    await initBarba();
})();