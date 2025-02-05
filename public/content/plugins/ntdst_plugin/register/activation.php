<?php

return function ($app) {

    //load textdomain
    add_action( 'init', function() use ($app ) {
        load_plugin_textdomain( $app->text_domain, false, WP_CONTENT_DIR . '/languages/' );
    } );

    add_action('wp_insert_site', function ($new_site) use ($app) {
        if(is_plugin_active_for_network('ntdst_plugin/ntdst_plugin.php')) {
            // do activation stuff
        }
    });

    register_activation_hook($app->file()->file, function ($network_wide) use ($app) {
        // do activation stuff
    });

    register_deactivation_hook($app->file()->file, function ($network_wide) {
        // do de-activation stuff
    });

};