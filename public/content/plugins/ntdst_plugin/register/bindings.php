<?php

use Netdust\APIInterface;

return function ($app) {

    //bind API
    $app->container()->singleton( APIInterface::class, \Netdust\Std\NTDSTServiceProvider::class );
    $app->extend( $app->container()->get( \Netdust\Std\NTDSTServiceProvider::class ) );
};