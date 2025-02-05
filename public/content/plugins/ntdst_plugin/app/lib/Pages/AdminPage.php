<?php

namespace Netdust\Std\Pages;

use Netdust\Services\Settings\Settings;

class AdminPage extends Settings
{
	public function __construct(  ) {
		$config = array_values(app()->config()['admin']);
		parent::__construct($config[0]['handle'], $config[0]['args']);
	}

	public function init() {
		$config = array_values(app()->config()['admin']);
		$cnf = $config[0]['args'];

		add_menu_page(
			$cnf['page_title'],
			$cnf['menu_title'],
			$cnf['capability'],
			$cnf['menu_slug'],
			[ $this, 'settingsPage' ],
			$cnf['icon'],
			$cnf['position']
		);

		add_submenu_page(
			$cnf['menu_slug'],
			'All Articles',
			'All Articles',
			'edit_posts',
			'edit.php'
		);
		remove_menu_page( 'edit.php' );

		// Remove existing parent menu.
		$this->change_post_object_label();
		$this->highlight_website_menu_for_posts();

		foreach(($cnf['sections']??[]) as $slug => $param) {
			$section = $this->addSection( $param['name'], $slug );
			foreach(($param['groups']??[]) as $sslug => $pparam) {
				$group = $section->addGroup( $pparam['name'], $sslug );
				$group->description( $pparam['description']??'' );
				$group->collapsed( $pparam['open']??false );
				foreach(($pparam['fields']??[]) as $ssslug => $ppparam) {
					$group->addField( $ppparam );
				}
			}
		}
	}

	public function highlight_website_menu_for_posts() {

		add_action('admin_head', function () {
			$config = array_values(app()->config()['admin']);
			$cnf = $config[0]['args'];

			global $parent_file, $submenu_file;

			$screen = get_current_screen();

			// Check if we're on the Posts page or any of its subpages
			if ($screen && $screen->post_type === 'post') {
				$parent_file = $cnf['menu_slug'];  // Keep your custom menu open
				$submenu_file = 'edit.php';       // Highlight the Posts submenu
			}
		});
	}

	public function change_post_object_label() {
		global $wp_post_types;
		$labels = &$wp_post_types['post']->labels;
		$labels->name = 'Articles';
		$labels->singular_name = 'Article';
		$labels->add_new = 'Add Article';
		$labels->add_new_item = 'Add Article';
		$labels->edit_item = 'Edit Article';
		$labels->new_item = 'Article';
		$labels->view_item = 'View Article';
		$labels->search_items = 'Search Articles';
		$labels->not_found = 'No Articles found';
		$labels->not_found_in_trash = 'No Articles found in Trash';
	}

}