// barba-animation.js
export class BarbaAnimation {
    constructor(options = {}) {
        this.config = {
            animationDuration: 500,
            overlaySelectors: { top: '.overlay-top', bottom: '.overlay-bottom' },
            ...options
        };
    }

    // === animateOut – EXACT COPY FROM ORIGINAL ===
    out(container) {
        return new Promise((resolve) => {
            const overlays = this._getOverlays();

            if (!overlays.top || !overlays.bottom) {
                setTimeout(resolve, this.config.animationDuration);
                return;
            }

            this._resetOverlays(overlays, 'offscreen');
            this._forceReflow(overlays);

            requestAnimationFrame(() => {
                this._updateOverlays(overlays, 'closing');
                this._handleAnimationEnd(overlays, resolve);
            });
        });
    }

    // === animateIn – EXACT COPY FROM ORIGINAL (with container) ===
    in(container) {
        return new Promise((resolve) => {
            const overlays = this._getOverlays();

            if (!overlays.top || !overlays.bottom) {
                container.style.opacity = '1';
                setTimeout(resolve, this.config.animationDuration);
                return;
            }

            this._resetOverlays(overlays, 'closing');
            this._prepareContainer(container);
            this._forceReflow(overlays);

            requestAnimationFrame(() => {
                this._updateOverlays(overlays, 'opening');
                this._showContainer(container);
                this._handleAnimationEnd(overlays, resolve);
            });
        });
    }

    // === Helper Methods – EXACT COPIES ===
    _getOverlays() {
        return {
            top: document.querySelector(this.config.overlaySelectors.top),
            bottom: document.querySelector(this.config.overlaySelectors.bottom)
        };
    }

    _resetOverlays(overlays, className) {
        overlays.top.className = `overlay-top ${className}`;
        overlays.bottom.className = `overlay-bottom ${className}`;
    }

    _updateOverlays(overlays, className) {
        overlays.top.classList.remove('offscreen');
        overlays.top.classList.add(className);
        overlays.bottom.classList.remove('offscreen');
        overlays.bottom.classList.add(className);
    }

    _prepareContainer(container) {
        container.style.display = 'block';
        container.style.zIndex = '1000';
    }

    _showContainer(container) {
        container.style.transition = 'opacity 0.5s ease';
        container.style.opacity = '1';
    }

    _forceReflow(overlays) {
        overlays.top.offsetHeight;
        overlays.bottom.offsetHeight;
    }

    _handleAnimationEnd(overlays, resolve) {
        let completed = 0;
        const onEnd = () => {
            if (++completed === 2) {
                this._hideOverlays(overlays);
                resolve();
            }
        };

        overlays.top.addEventListener('transitionend', onEnd, { once: true });
        overlays.bottom.addEventListener('transitionend', onEnd, { once: true });

        setTimeout(() => {
            if (completed < 2) {
                this._hideOverlays(overlays);
                resolve();
            }
        }, this.config.animationDuration);
    }

    _hideOverlays(overlays) {
        overlays.top.classList.add('hidden');
        overlays.bottom.classList.add('hidden');
    }
}