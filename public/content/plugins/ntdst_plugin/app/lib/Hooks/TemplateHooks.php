<?php

namespace Netdust\Std\Hooks;


class TemplateHooks {
    protected function get_merge_tags( ) {
        return apply_filters( 'merge_tags', array(
            '{post_id}' => get_queried_object_id(),
        ));
    }

    protected function add_merge_tags( $text, $merge_tags = array() ) {
        foreach ( $merge_tags as $key => $value ) {
            $text = str_replace( $key, $value, $text );
        }
        return wptexturize( $text );
    }

    public function merge_tags(  $text ) {
        return $this->add_merge_tags( $text, $this->get_merge_tags( ) );
    }

	public function add_roles_to_class( $classes ) {
		if( is_user_logged_in() ) {
			$user_role = wp_get_current_user()->roles;
			$classes .= ' user-role-' . implode("_",$user_role);
		}
		return $classes;
	}

    public function custom_single_template($single) {

        global $post;

        /* Checks for single template by post type */
        if ( $post->post_type == 'post' ) {
            $template = app()->file()->template_path( 'front/post/single-standard.php' ) ;
            if ( file_exists( $template  ) ) {
                return $template;
            }
        }

        return $single;

    }
}