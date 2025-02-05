<?php
/**
 *
 * @link              https://netdust.be
 * @since             1.0.0-dev
 * @package           Netdust\ntdst
 * @author            Stefan Vandermeulen
 *
 * @wordpress-plugin
 * Plugin Name:       Netdust plugin
 * Plugin URI:        https://netdust.be
 * Description:       A plugin for custom web functionality.
 * Version:           3.0.0
 * Author:            Stefan Vandermeulen
 * Author URI:        https://netdust.be
 * Text Domain:       ntdst
 */



defined( 'ABSPATH' ) || exit;

define( 'APP_PLUGIN_FILE', __FILE__ );


add_action( 'plugins_loaded', '_load_ndst', 1 );

interface ntdst {}


function _load_ndst() {

    \Netdust\App::boot( ntdst::class, [
        'file'                => APP_PLUGIN_FILE,
        'text_domain'         => 'ntdst',
        'version'             => '1.0.0',
        'minimum_wp_version'  => '6.8',
        'minimum_php_version' => '8.2',
        'config_path'         => '/config',
        'build_path'          => '/app'
    ] );

}

