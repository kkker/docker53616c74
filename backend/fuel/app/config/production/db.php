<?php
/**
 * The production database settings. These get merged with the global settings.
 */

return array(
	'default' => array(
		'connection'  => array(
			'dsn'        => 'mysql:host=localhost;dbname=demo_prod',
			'username'   => 'fuel_app',
			'password'   => 'super_secret_password',
		),
	),
);
