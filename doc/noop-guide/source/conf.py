import os
import subprocess
extensions = []
source_suffix = '.rst'
master_doc = 'index'
project = u'Fuel Noop Tests Guide'
bug_tag = u'noop-guide'
copyright = u'2015, Fuel for Fuel for OpenStack contributors'
version = '1.0.0'
release = '1.0.0'
giturl = u'http://git.openstack.org/cgit/openstack/fuel-library/tree/doc/noop-guide/source'
git_cmd = ["/usr/bin/git", "log", "|", "head", "-n1", "|", "cut", "-f2",
           "-d'", "'"]
gitsha = subprocess.Popen(git_cmd,
                          stdout=subprocess.PIPE).communicate()[0]
html_context = {"gitsha": gitsha, "bug_tag": bug_tag,
                "giturl": giturl}
pygments_style = 'sphinx'
html_last_updated_fmt = '%Y-%m-%d %H:%M'
html_use_index = False
html_show_sourcelink = False
htmlhelp_basename = 'noop-guide'
html_copy_source = False
latex_elements = {
    # The paper size ('letterpaper' or 'a4paper').
    # 'papersize': 'letterpaper',
    # The font size ('10pt', '11pt' or '12pt').
    # 'pointsize': '10pt',
    # Additional stuff for the LaTeX preamble.
    # 'preamble': '',
}
latex_documents = [
    ('index', 'NoopTestsGuide.tex', u'User Guide',
     u'Fuel for OpenStack contributors', 'manual'),
]
man_pages = [
    ('index', 'nooptestsguide', u'User Guide',
     [u'Fuel for OpenStack contributors'], 1)
]
texinfo_documents = [
    ('index', 'NoopTestsGuide', u'User Guide',
     u'Fuel for OpenStack contributors', 'NoopTestsGuide',
     'This guide shows OpenStack end users how to create and manage resources '
     'in an OpenStack cloud with the OpenStack dashboard and OpenStack client '
     'commands.', 'Miscellaneous'),
]
pdf_documents = [
    ('index', u'NoopTestsGuides', u'End User Guide', u'Fuel for OpenStack contributors')
]
