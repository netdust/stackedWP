# WordPress Skeleton

This is simply a skeleton repo for a WordPress site. It's heavily inspired on Wordpress Skeleton from markjaquith
## Assumptions

* WordPress as a Git submodule in `/wp/`
* Custom content directory in `/content/` (cleaner, and also because it can't be in `/wp/`)
* Starter plugins as a Git submodule in `/content/plugins/`
* `wp-config.php` in the root (because it can't be in `/wp/`)
* All writable directories are symlinked to similarly named locations under `/shared/`.

## Usage
start with creating a LocalWP copy of this repo ( use a zip to copy the project )
then `git submodule sync` `git submodule init` `git submodule update`

this will add wordpress and plugins to the project

