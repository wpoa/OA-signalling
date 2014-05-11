# -*- coding: utf-8  -*-

__version__ = '$Id: e9c86d60b4e280a2879c5a28cd75c363a113e7ac $'

from pywikibot import family


# The wikispecies family
class Family(family.WikimediaFamily):
    def __init__(self):
        super(Family, self).__init__()
        self.name = 'species'
        self.langs = {
            'species': 'species.wikimedia.org',
        }
        self.interwiki_forward = 'wikipedia'
