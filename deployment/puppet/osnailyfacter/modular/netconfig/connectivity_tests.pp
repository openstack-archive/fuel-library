notice('MODULAR: connectivity_tests.pp')
# Pull the list of repos from hiera
$repos_setup = hiera('repo_setup')
# test that the repos are accessible
url_accessible($repo_setup['repos'])
