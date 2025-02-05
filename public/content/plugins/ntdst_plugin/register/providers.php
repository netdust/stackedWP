<?php


return function ($app) {

    /**
     * register the  serviceproviders
     */
    $providers = [
        // Application
        '\Netdust\Std\Providers\Application',
        '\Netdust\Std\Providers\ApplicationAdmin',
        '\Netdust\Std\Providers\ApplicationFront',

    ];

    foreach($providers as $key => $value ) {
        if( is_array($value) ) // map alias too
            call_user_func_array( [$app->container,'register'], $value );
        else {
            $app->container->register( $value );
        }
    };

};