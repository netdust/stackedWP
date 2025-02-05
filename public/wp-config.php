<?php

// ==============================================================
// Table prefix
// Change this if you have multiple installations in the same database
// ==============================================================


// ===================================================
// Load database info and local development parameters
// ===================================================
$environments = array(
	'local'       => 'ntdst.test',
	'staging'     => 'staging.ntdst.be',
	'production'  => 'ntdst.be'
);


$currentHost = $_SERVER['HTTP_HOST'];
if (in_array($currentHost, array_values($environments))) {
	define('ENVIRONMENT', array_search($currentHost, $environments));
}

// Exit if ENVIRONMENT is undefined
if (!defined('ENVIRONMENT'))
	exit('No database configured for this host');

$wp_db_config = 'env/wp-config-' . ENVIRONMENT . '.php';
if (!file_exists(__DIR__ . '/' . $wp_db_config))
	exit('No database configuration found for this host');


require_once($wp_db_config);

// ========================
// Custom Content Directory
// ========================
define( 'WP_CONTENT_DIR', dirname( __FILE__ ) . '/content' );
define( 'WP_CONTENT_URL', 'https://' . $_SERVER['HTTP_HOST'] . '/content' );

// ================================================
// You almost certainly do not want to change these
// ================================================
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

// ==============================================================
// Salts, for security
// Grab these from: https://api.wordpress.org/secret-key/1.1/salt
// ==============================================================
define('AUTH_KEY',         ' z#+~NRdaTL?}^1xtM8]P!?&r7)uPD~9myp%GO.^+FXI-<-(nWu.sE43?s7Ao*LX');
define('SECURE_AUTH_KEY',  'YB0gZ>.>C]p:_|3)jyq@Q!msgg^/C=N0rjxb7~If`hAIq]~(s__|as&T#o!0@1[x');
define('LOGGED_IN_KEY',    'pr{(Y+&!~?AIUT?Ax$~#nETOvmAkc;b:!+ea<6q3Pv%7ok7C/ZU_M] (#tJeJ{fM');
define('NONCE_KEY',        '|b>/9@vMrfmWQW|tp=q@!,hRar8o0=/HCkkT6#|a[B-av/BDCf-1E]bw*k&4/<ls');
define('AUTH_SALT',        'aMXR+9zl-L{<}{.I~)_r<Qf]#}0jx?72>:++CZ?!zj@(y[R+Q6TR?91sTYv.k?/N');
define('SECURE_AUTH_SALT', '*QaA$}N#S@.X<{R~t:bT4} vx+gAq{*)TM/y+%5%8SPQB}YeUI6O+r$-Qb4Ixh(Q');
define('LOGGED_IN_SALT',   'HzojT+]bl J:T-4-p <-pl0:K~U^!}cye d-+@%~>{9)i*vpt6]<(LB?]=A@)]HY');
define('NONCE_SALT',       '0;C~r-&rcX6W^[Sdw2IMy6{qC/$-LG*klHxqaI4H~&66eG/ol]gz)`-&>L8?O3F@');


// ================================
// SSL
// Force SSL on login and admin
// ================================
//define('FORCE_SSL_LOGIN', true);
//define('FORCE_SSL_ADMIN', true);

// ================================
// Language
// Leave blank for American English
// ================================
define( 'WPLANG', '' );

// ================================
// Theme
// set the default theme
// ================================
//define('WP_DEFAULT_THEME', 'ntdstheme');
//define('DISALLOW_FILE_EDIT', true);
//define('DISALLOW_FILE_MODS', true);

// ================================
// Revisions
// ================================
define('WP_POST_REVISIONS', 10);

// ===========
// Hide errors
// ===========
if ( !defined( 'WP_DEBUG_DISPLAY' ) ) {
	ini_set( 'display_errors', 0 );
	define( 'WP_DEBUG_DISPLAY', false );
}

// ===========
// Enable cach
// ===========
define('WP_CACHE', true);

// =================================================================
// Debug mode
// Debugging? Enable these. Can also enable them in local-config.php
// =================================================================
// define( 'SAVEQUERIES', true );
if ( !defined( 'WP_DEBUG' ) )
	define( 'WP_DEBUG', true );
if ( !defined( 'WP_DEBUG_LOG' ) )
	define( 'WP_DEBUG_LOG', true );

// ======================================
// Load a Memcached config if we have one
// ======================================
if ( file_exists( dirname( __FILE__ ) . '/memcached.php' ) )
	$memcached_servers = include( dirname( __FILE__ ) . '/memcached.php' );

// ===========================================================================================
// This can be used to programatically set the stage when deploying (e.g. production, staging)
// ===========================================================================================
define( 'WP_STAGE', '%%WP_STAGE%%' );
define( 'STAGING_DOMAIN', '%%WP_STAGING_DOMAIN%%' ); // Does magic in WP Stack to handle staging domain rewriting

// ===================
// Bootstrap WordPress
// ===================
if ( !defined( 'ABSPATH' ) )
	define( 'ABSPATH', dirname( __FILE__ ) . '/wp/' );
require_once( ABSPATH . 'wp-settings.php' );
