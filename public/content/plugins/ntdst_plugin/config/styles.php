<?php


return [

    \Netdust\Service\Assets\Style::class => [
        [
            'handle'      => 'custom-css',
            'src'         => \Netdust\App::file()->asset_url( 'css', 'custom.css' ),
            'to'          => [ 'front' ]
        ]
    ]

];
