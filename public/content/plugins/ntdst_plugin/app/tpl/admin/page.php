<?php

declare(strict_types=1);

/**
 * Settings page template
 *
 * @var Settings $this Settings instance.
 */

if (!isset($currentSection)) {
    $currentSection = '';
}

?>

<div class="ntdst-settings <?php echo esc_attr($this->handle); ?>-settings">

    <header class="ntdst-header">
        <div class="ntdst-container">
            <div class="ntdst-logo">
                <img src="<?php echo esc_url( app()->file()->asset_url( 'css', '/img/logo.svg' ) ); ?>">
            </div>
            <div class="ntdst-float-right">
                <h2><?php echo esc_attr($this->args['page_title']); ?></h2>
            </div>
        </div>
    </header>
    <div style="margin-top:30px;">
        <div class="ntdst-container">
            <div class="ntdst-notices-area">
                <div class="ntdst-container">

                </div>
            </div>

    <?php if (empty($sections)) : ?>
        <p>
            <?php
            esc_html_e(
                'No Settings available at the moment',
                app()->text_domain
            );
            ?>
        </p>
    <?php else : ?>
        <div
                id="settings-section"
                class=" box section">
            ok
        </div>
        <div class="menu-col">

            <?php do_action($this->handle . '/settings/sidebar/before'); ?>

            <ul class="menu-list box">
                <?php foreach ($this->getSections() as $sectionSlug => $section) : ?>
                    <?php
                    $class = ($sectionSlug === $currentSection)
                        ? 'current'
                        : '';
                    $pageUrl = remove_query_arg('updated');
                    $url = add_query_arg(
                        'section',
                        $sectionSlug,
                        $pageUrl
                    );
                    ?>
                    <li class="<?php echo esc_attr($class); ?>">
                        <a
                                href="
							<?php
                                echo esc_attr(
                                    $url
                                );
                                ?>
									"
                        ><?php echo esc_html($section->name()); ?></a>
                    </li>
                <?php endforeach ?>
            </ul>

            <div class="box">
                <h3> Custom Development	</h3>
                <p>
                    We at Netdust can create a custom WordPress plugin for you!	</p>
                <a href="https://netdust.be/custom-development" class="button button-secondary" target="_blank">Find out more</a></div>

            <?php do_action($this->handle . '/settings/sidebar/after'); ?>

        </div>

        <?php $section = $this->getSection($currentSection); ?>

        <div
                id="settings-section-<?php echo esc_attr($section->slug()); ?>"
                class="setting-col box section-<?php echo esc_attr($section->slug()); ?>"
        >

            <?php do_action($this->handle . '/settings/section/' . $section->slug() . '/before'); ?>

            <form
                    action="<?php echo esc_attr(admin_url('admin-post.php')); ?>"
                    method="post"
                    enctype="multipart/form-data"
            >

                <?php
                wp_nonce_field(
                    'save_' . $this->handle . '_settings',
                    'nonce'
                );
                ?>

                <input
                        type="hidden"
                        name="action"
                        value="save_<?php echo esc_attr($this->handle); ?>_settings"
                >

                <?php
                /**
                 * When you have only checkboxed in the section, no data in POST is returned.
                 * This fields adds a dummy value for form handler so
                 * it could grab the section name and parse all defined fields
                 */
                ?>
                <input
                        type="hidden"
                        name="<?php echo esc_attr($this->handle) . '_settings[' . esc_attr($section->slug()) . ']'; ?>"
                        value="section_buster"
                >

                <?php $groups = $section->getGroups(); ?>

                <?php foreach ($groups as $group) : ?>
                    <div
                            id="settings-group-<?php echo esc_attr($group->slug()); ?>"
                            class="setting-group group-<?php echo esc_attr($group->slug()); ?>"
                    >
                        <div
                                class="setting-group-header
							<?php
                                echo esc_attr(
                                    ($group->collapsed())
                                        ? ''
                                        : 'open'
                                );
                                ?>
														"
                        >
                            <h3><?php echo esc_html($group->name()); ?></h3>

                            <?php $description = $group->description(); ?>

                            <?php if (!empty($description)) : ?>
                                <p class="description"><?php echo esc_html($description); ?></p>
                            <?php endif ?>
                        </div>

                        <?php do_action($this->handle . '/settings/group/' . $group->slug() . '/before'); ?>
                        <table class="form-table">

                            <?php foreach ($group->getFields() as $field) : ?>
                                <tr
                                        id="settings-field-
									<?php
                                        echo esc_attr(
                                            $group->slug()
                                        );
                                        ?>
																	-<?php echo esc_attr($field->slug()); ?>"
                                        class="field-<?php echo esc_attr($field->slug()); ?>"
                                >
                                    <th>
                                        <label for="<?php echo esc_attr($field->inputId()); ?>">
                                            <?php
                                            echo esc_html(
                                                $field->name()
                                            );
                                            ?>
                                        </label>
                                    </th>
                                    <td>
                                        <?php
                                        $field->render();
                                        $fieldDescription = $field->description();
                                        ?>
                                        <?php if (!empty($fieldDescription)) : ?>
                                            <small class="description">
                                                <?php
                                                echo wp_kses(
                                                    $fieldDescription,
                                                    wp_kses_allowed_html('ntdst/field_description')
                                                );
                                                ?>
                                            </small>
                                        <?php endif ?>
                                    </td>
                                </tr>

                            <?php endforeach ?>

                        </table>
                        <?php
                        do_action(
                            $this->handle . '/settings/sections/after',
                            $group->slug()
                        );
                        ?>

                    </div>

                <?php endforeach ?>

                <?php if (!empty($groups)) : ?>
                    <?php submit_button(); ?>
                <?php endif ?>

            </form>

            <?php do_action($this->handle . '/settings/section/' . $section->slug() . '/after'); ?>

        </div>

    <?php endif ?>
        </div>
    </div>
</div>
