notice('MODULAR: connectivity_tests.pp')
# Pull the list of repos from hiera
$repo_setup = hiera('repo_setup')
# test that the repos are accessible
url_available($repo_setup['repos'])
