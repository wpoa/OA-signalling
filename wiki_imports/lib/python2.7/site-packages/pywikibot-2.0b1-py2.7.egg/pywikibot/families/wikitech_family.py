# -*- coding: utf-8  -*-

__version__ = '$Id: bf739dea02a7ecc02e263170835091cb2ee06cf2 $'

from pywikibot import family


# The Wikitech family
class Family(family.Family):

    def __init__(self):
        super(Family, self).__init__()
        self.name = 'wikitech'
        self.langs = {
            'en': 'wikitech.wikimedia.org',
        }

    def version(self, code):
        return '1.21wmf8'

    def protocol(self, code):
        return 'https'
