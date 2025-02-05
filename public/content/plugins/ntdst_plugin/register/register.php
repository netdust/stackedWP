<?php


use Netdust\Logger\Logger;


return function ($app) {

    Logger::logger()->log_level = 'debug';

    add_action( 'after_setup_theme', function() use ( $app ) {
        setup_blocks($app);
        setup_shortcodes($app);
        setup_user_roles($app);
        setup_post_types($app);
        setup_script_styles($app);
    } );

};

function setup_blocks($app) {
    foreach( ($app->config()['blocks']??[]) as $build => $module ) {
        $module = is_array( reset($module) ) ? $module : [$module];
        foreach($module as $args ) {
            app()->make( $args['block_name'], $build, $args, [], true );
        }
    }
    foreach( ($app->config()['patterns']??[]) as $build => $module ) {
        $module = is_array( reset($module) ) ? $module : [$module];
        foreach($module as $args ) {
            app()->make( $args['type'], $build, $args, [], true );
        }
    }
}

function setup_shortcodes($app) {
    foreach( ($app->config()['shortcodes']??[]) as $build => $module ) {
        $module = is_array( reset($module) ) ? $module : [$module];
        foreach($module as $args ) {
            app()->make( $args['tag'], $build, $args, ['do_actions'], true );
        }
    }
}

function setup_user_roles($app) {
    foreach( ($app->config()['roles']??[]) as $build => $module ) {
        $module = is_array( reset($module) ) ? $module : [$module];
        foreach($module as $args ) {
            app()->make( $args['role'], $build, $args, ['do_actions'], true );
        }
    }
}


function setup_post_types($app) {
    foreach( ($app->config()['posts']??[]) as $build => $module ) {
        $module = is_array( reset($module) ) ? $module : [$module];
        foreach($module as $args ) {
            app()->make( $args['type'], $build, $args, ['do_actions'], true );
        }
    }
    foreach( ($app->config()['taxonomies']??[]) as $build => $module ) {
        $module = is_array( reset($module) ) ? $module : [$module];
        foreach($module as $args ) {
            app()->make( $args['taxonomy'], $build, $args, ['do_actions'], true );
        }
    }
}

function setup_script_styles($app) {

    foreach( ($app->config()['styles']??[]) as $build => $module ) {
        $module = is_array( reset($module) ) ? $module : [$module];
        foreach($module as $args ) {
            app()->make( $args['handle'], $build, $args, [], true )
                ->to( $args['to'] ?? [] )
                ->register();
        }
    }
    foreach( ($app->config()['scripts']??[]) as $build => $module ) {
        $module = is_array( reset($module) ) ? $module : [$module];
        foreach($module as $args ) {
            app()->make( $args['handle'], $build, $args, [], true )
                ->setDependencies( $args['dependencies'] ?? [] )
                ->setLocalizedVar( $args['localized'] ?? '' )
                ->setInFooter( $args['footer'] ?? true )
                ->to( $args['to'] ?? [] )
                ->register();
        }
    }
}
