# -*- coding: utf-8  -*-

__version__ = '$Id: 27d5f4b749517d70713132ceca7a1083730d0f30 $'

from pywikibot import family


# The test wikipedia family
class Family(family.WikimediaFamily):
    def __init__(self):
        super(Family, self).__init__()
        self.name = 'test'
        self.langs = {
            'test': 'test.wikipedia.org',
        }
