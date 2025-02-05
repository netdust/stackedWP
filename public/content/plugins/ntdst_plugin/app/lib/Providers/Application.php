<?php

namespace Netdust\Std\Providers;

use Netdust\Http\Request;
use Netdust\Std\Hooks\TemplateHooks;
use Netdust\Std\Hooks\ApplicationHooks;

class Application extends \Netdust\Core\ServiceProvider {

    /**
     * early registration, init providers and settings here
     */
    public function register() {

        $this->container->singleton( ApplicationHooks::class );
        $this->container->singleton( TemplateHooks::class );

    }

    /**
     * called right after 'after_setup_theme'
     * provider can start doing some work
     */
    public function boot() {
        $this->setup_hooks(); 
    }

    public function setup_hooks() {


        add_filter( "doing_it_wrong_trigger_error", "__return_false" );

        add_action('wp_head', function() {
            if (is_search() || app(Request::class)->hasQuery() ) {
                echo '<meta name="robots" content="noindex, nofollow">';
            }
        });

        add_action( 'init', function() {
            unregister_taxonomy_for_object_type( 'category', 'post' );
            add_post_type_support( 'page', 'excerpt' );
        } );

        /*
        add_action( 'init', function() {
            \Yootheme\Event::on(
                'theme.breadcrumbs',
                $this->container->callback(ApplicationHooks::class, 'change_breadcrumbs')
            );
        });*/


        add_action(
            'init',
            $this->container->callback(ApplicationHooks::class, 'tags_support_all')
        );
        add_action(
            'pre_get_posts',
            $this->container->callback(ApplicationHooks::class, 'tags_support_query')
        );

        add_filter(
            'post_link',
            $this->container->callback(ApplicationHooks::class, 'custom_artikels_permalink_post')
            , 10, 3 );
        add_filter(
            'term_link',
            $this->container->callback(ApplicationHooks::class, 'custom_artikels_permalink_archive')
            , 10, 3 );
        add_action(
            'generate_rewrite_rules',
            $this->container->callback(ApplicationHooks::class, 'custom_rewrite_rules')
        );

        add_action(
            'plugins_loaded',
            $this->container->callback(ApplicationHooks::class, 'load_textdomain')
        );



    }

}