<?php

namespace Netdust\Std\Providers;

use Netdust\Std\Hooks\ApplicationHooks;
use Netdust\Std\Hooks\TemplateHooks;


class ApplicationAdmin extends \Netdust\Core\ServiceProvider {

    /**
     * early registration, init providers and settings here
     */
    public function register() {

        $this->container->singleton(TemplateHooks::class);

    }

    /**
     * called right after 'after_setup_theme'
     * provider can start doing some work
     */
    public function boot() {
        $this->setup_hooks();
    }

    protected function setup_hooks() {

	    add_action(
		    'admin_body_class',
		    $this->container->callback(TemplateHooks::class, 'add_roles_to_class')
	    );

    }
}