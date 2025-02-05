window.ntdst = window.ntdst || {};

((exports) => {
    "use strict";

    exports.settings = {
        init() {
            this.setupListeners();
            this.setupView();
        },

        setupListeners() {
        },

        setupView() {
        },

    };

    document.addEventListener("DOMContentLoaded", () => {
        exports.settings.start();
    });

})(window.ntdst);
