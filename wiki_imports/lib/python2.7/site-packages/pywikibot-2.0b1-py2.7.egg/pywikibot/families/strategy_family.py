# -*- coding: utf-8  -*-

__version__ = '$Id: 8ad960e9bbc1d10ad7384dff4e12a7b69d44772d $'

from pywikibot import family


# The Wikimedia Strategy family
class Family(family.WikimediaFamily):
    def __init__(self):
        super(Family, self).__init__()
        self.name = 'strategy'
        self.langs = {
            'strategy': 'strategy.wikimedia.org',
        }
        self.interwiki_forward = 'wikipedia'

    def dbName(self, code):
        return 'strategywiki_p'
