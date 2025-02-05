<?php

namespace Netdust\Std\Hooks;


use Netdust\Http\Request;
use Netdust\Logger\Logger;

class ApplicationHooks
{

    public function change_breadcrumbs( $items ) {


        return $items;
    }

    /***********************************
    Modifying permalinks
     ************************************/
    /**
     * Modify Permalinks for the Case Studies Category
     *
     * @author Nikki Stokes
     * @link https://thebizpixie.com/
     *
     * @param string $permalink
     * @param WP_Post $post
     * @param array $leavename
     */
    // Modify the individual case study post permalinks
    public function custom_artikels_permalink_post( $permalink, $post, $leavename ) {
        // Get the categories for the post
        if (  $post->post_type == "post" && $post->post_status === 'publish') {
            $permalink = trailingslashit( home_url('/artikels/'. $post->post_name . '/' ) );
        }
        return $permalink;
    }


    // Modify the archive permalink
    public function custom_artikels_permalink_archive( $permalink, $term, $taxonomy ){
        // Get the category ID
        $category = get_taxonomy( $term->taxonomy );
        // Check for desired category
        if( !empty( $category ) && in_array( 'post', $category->object_type ) ) {
            $permalink = trailingslashit( home_url('/artikels/'. $category->name . '/' . $term->slug .'/') );
        }

        return $permalink;
    }

    public function custom_rewrite_rules( $wp_rewrite ) {
        // This rule will match the post name in /artikels/%postname%/ structure
        $new_rules['^artikels/([^/]+)/?$'] = 'index.php?name=$matches[1]';
        $new_rules['^artikels/?$'] = 'index.php?page_id=1163';
        $wp_rewrite->rules = $new_rules + $wp_rewrite->rules;

        return $wp_rewrite;
    }



    public function load_textdomain() {
        // Set filter for plugin language directory
        $lang_dir =  app()->file()->dir_path('languages/');
        $lang_dir = apply_filters( app()->text_domain . '_languages_directory', $lang_dir );

        // Load plugin translation file
        load_plugin_textdomain( app()->text_domain, false, $lang_dir );
    }

    // add tag support to pages
    public function tags_support_all() {
        register_taxonomy_for_object_type('post_tag', 'page');
    }

// ensure all tags are included in queries
    public function tags_support_query($wp_query) {
        if ($wp_query->get('tag')) $wp_query->set('post_type', 'any');
    }

}