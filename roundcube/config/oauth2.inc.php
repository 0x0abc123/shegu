<?php
$config['oauth_provider'] = 'generic';
$config['oauth_provider_name'] = 'OFFICEOAUTH2IDPNAME';
$config['oauth_client_id'] = 'OFFICEOAUTH2CLIENTID';
$config['oauth_client_secret'] = 'OFFICEOAUTH2CLIENTSECRET';
$config['oauth_auth_uri'] = 'OFFICEOAUTH2AUTHURL';
$config['oauth_token_uri'] = 'OFFICEOAUTH2TOKENURL';
$config['oauth_identity_uri'] = 'OFFICEOAUTH2USERINFOURL';

// Optional: disable SSL certificate check on HTTP requests to OAuth server. For possible values, see:
// http://docs.guzzlephp.org/en/stable/request-options.html#verify
$config['oauth_verify_peer'] = false;

$config['oauth_scope'] = 'email openid profile';
$config['oauth_identity_fields'] = ['email'];

// Boolean: automatically redirect to OAuth login when opening Roundcube without a valid session
$config['oauth_login_redirect'] = true;
?>
