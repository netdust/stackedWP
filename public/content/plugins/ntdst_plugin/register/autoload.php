<?php


return function ($app) {

    \Netdust\Core\AutoLoader::setup_autoloader( [
        'Netdust\Std\\'=> $app->file()->dir_path('app/lib/'),
        'Netdust\Services\\'=> $app->file()->dir_path('services/')
    ] );

};