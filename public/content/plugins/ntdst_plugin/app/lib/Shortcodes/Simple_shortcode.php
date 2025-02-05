<?php

namespace Netdust\Std\Shortcodes;

use Netdust\App;
use Netdust\Logger\Logger;
use Netdust\Service\Shortcodes\Shortcode;

class Simple_shortcode extends Shortcode
{

    protected function shortcode_actions( array $atts ): string {
        return App::template()->render( 'shortcodes/' . $this->tag, $atts );
    }

}