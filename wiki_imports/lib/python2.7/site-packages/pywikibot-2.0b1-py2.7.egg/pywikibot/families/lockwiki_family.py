# -*- coding: utf-8  -*-

__version__ = '$Id: 97d06e7474f04608d81c584b35f20294af6b2d6d $'

from pywikibot import family


# The locksmithwiki family
class Family(family.Family):
    def __init__(self):
        family.Family.__init__(self)
        self.name = 'lockwiki'
        self.langs = {
            'en': 'www.locksmithwiki.com',
        }

    def scriptpath(self, code):
        return '/lockwiki'

    def version(self, code):
        return '1.15.1'

    def nicepath(self, code):
        return "%s/" % self.path(self, code)
