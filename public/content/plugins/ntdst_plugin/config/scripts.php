<?php

use Netdust\App;
use \Netdust\Service\Scripts\AdminScript;
use \Netdust\Service\Scripts\FrontScript;

return [
    \Netdust\Service\Assets\Script::class => [

        [
            'handle'        => 'common-js',
            'src'           => App::file()->asset_url('js', 'common.js'),
            'to'            => [ 'front' ],
            'dependencies'  => ['jquery']
        ]
    ]

];


