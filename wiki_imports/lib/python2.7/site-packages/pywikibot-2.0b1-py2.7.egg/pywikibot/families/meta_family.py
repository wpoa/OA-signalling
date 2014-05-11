# -*- coding: utf-8  -*-

__version__ = '$Id: 27cbdb6f12e34eb9a7bd04468d71e6a41c384e60 $'

from pywikibot import family


# The meta wikimedia family
class Family(family.WikimediaFamily):
    def __init__(self):
        super(Family, self).__init__()
        self.name = 'meta'
        self.langs = {
            'meta': 'meta.wikimedia.org',
        }
        self.interwiki_forward = 'wikipedia'
        self.cross_allowed = ['meta', ]
