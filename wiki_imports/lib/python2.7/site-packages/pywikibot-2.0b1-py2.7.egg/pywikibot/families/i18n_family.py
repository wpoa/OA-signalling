# -*- coding: utf-8  -*-

__version__ = '$Id: f1dea707d147f6cfed4ccb48450ce0edbba95103 $'

from pywikibot import family


# The Wikimedia i18n family
class Family(family.Family):

    def __init__(self):
        family.Family.__init__(self)
        self.name = 'i18n'
        self.langs = {
            'i18n': 'translatewiki.net',
        }

    def version(self, code):
        return "1.23alpha"
