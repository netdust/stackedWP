<?php

namespace Netdust\Std;

use Netdust\Core\ServiceProvider;


class NTDSTServiceProvider extends ServiceProvider implements \Netdust\APIInterface
{


    public function add_posttypes( array $posttypes ): void {
        foreach( $posttypes as $build => $module ) {
            $module = is_array( reset($module) ) ? $module : [$module];
            foreach($module as $args ) {
                app()->make( $args['type']??$args['taxonomy'], $build, $args, ['do_actions'], true );
            }
        }
    }

    public function add_shortcodes( array $shortcodes ): void {
        foreach( $shortcodes as $build => $module ) {
            $module = is_array( reset($module) ) ? $module : [$module];
            foreach($module as $args ) {
                app()->make( $args['tag'], $build, $args, ['do_actions'], true );
            }
        }
    }

    /**
     * creates a new menupage
     */
    public function add_menupages( array $adminpages ): void {
        foreach( $adminpages as $build => $module ) {
            $module = is_array( reset($module) ) ? $module : [$module];
            foreach($module as $args ) {
                app()->make( $args['handle'], $build, $args, ['init'], true );
            }
        }
    }
    /**
     * adds a section or group to the main admin page
     */
    public function add_menu_settings( array $config ): void {


        $cnf = app()->config();
        $adminConfig = $cnf['admin'];
        $sections = $adminConfig[array_key_first($adminConfig)]['args']['sections'];

        foreach(($config??[]) as $slug => $param) {
            if( key_exists( $slug, $sections ) && key_exists( 'groups', $config[$slug] ) ) {
                if( !key_exists( 'groups', $sections[$slug] ) ) {
                    $sections[$slug]['groups'] = [];
                }
                $sections[$slug]['groups'] = array_merge( $sections[$slug]['groups'], $config[$slug]['groups'] );
            }
            else {
                $sections[ $slug ] = $param;
            }
        }


        $adminConfig[array_key_first($adminConfig)]['args']['sections'] = $sections;
        $cnf['admin'] = $adminConfig;


    }

}