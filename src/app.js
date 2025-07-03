
import UIkit from 'uikit';

import {page} from "./animations/page-anime.js";
import './animations/page-anime.css';

import {text} from "./animations/text-anime.js";
import './animations/text-anime.css';

export const app = {

    ajax(action, payload = {}, method = 'POST') {

        const cleanPayload = { ...payload };
        delete cleanPayload.action;
        delete cleanPayload.action2;

        // Step 1: Get nonce
        return UIkit.util.ajax(ntdst_data.ajax_url, {
            method: 'POST',
            responseType: 'json',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            data: 'action=get_nonce&next=' + encodeURIComponent(action),
        })
            .then(xhr => {
                const nonceData = xhr.response;
                if (!nonceData.success || !nonceData.data.nonce) {
                    throw new Error(nonceData.data?.message || ntdst_data.error_message);
                }

                cleanPayload.nonce = nonceData.data.nonce;
                cleanPayload.action = action;

                // Step 2: Do the actual request
                return UIkit.util.ajax(ntdst_data.ajax_url, {
                    method,
                    responseType: 'json',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    data: new URLSearchParams(cleanPayload).toString(),
                });
            })
            .then(xhr => {
                const response = xhr.response;
                if (!response || response.success === false) {
                    throw new Error(response?.data?.message || ntdst_data.ajax_fail_message);
                }
                return response;
            })
            .catch(error => {
                UIkit.notification({ message:"An error occurred. Please try again.", status:"error", pos: 'top-center', timeout: 3000 });
                throw error;
            });
    },

    start(opts = {}) {

        /*
        const parallax = new Parallax();
        parallax.init();

        // Example
        reveal.start({
            animationType: 'clipPathInset',
            duration: 100,
            ease: 'easeOutExpo'
        });*/


        page.start( );
        text.all( );

    }
};