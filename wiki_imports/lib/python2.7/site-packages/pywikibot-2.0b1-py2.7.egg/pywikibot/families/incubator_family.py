# -*- coding: utf-8  -*-

__version__ = '$Id: 11c92177ab93084552b8d68021da6545c4b7674f $'

from pywikibot import family


# The Wikimedia Incubator family
class Family(family.WikimediaFamily):
    def __init__(self):
        super(Family, self).__init__()
        self.name = 'incubator'
        self.langs = {
            'incubator': 'incubator.wikimedia.org',
        }
