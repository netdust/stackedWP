<?php

use Netdust\App;

return [
    \Netdust\Std\Pages\AdminPage::class => [
        'handle'=>'ntdst-website-settings',
        'args' => [
            'page_title' => 'NTDST Website',
            'menu_title' => 'NTDST Website',
            'capability' => 'read',
            'menu_slug' => 'ntdst-website-settings',
            'icon' => App::file()->asset_url( 'css', 'img/ntdst.png' ),
            'position' => 4,
            'sections' => [
                'settings-section' => [
                    'name'        => __( 'Settings' ),
                    'groups' => [
                        'settings-section-group' => [
                            'name'        => __( 'Group Settings' ),
                        ]
                    ]

                ]
            ]
        ]
    ]
];