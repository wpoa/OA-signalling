# coding: utf-8
import pywikibot

enws = pywikibot.Site('en', 'wikisource')
if not: enws.logged_in():
    enws.login()

WSPATH = 'Wikisource:WikiProject Academic Papers/OA-Signalling/'

class journal_artlicle():
    def __init__(self, title, wikitext):
        self.title = title
        self.wikitext = wikitext
        self.commons_filenames = list()
        self.suplementary_uris = list()
        self.categories = ['Category:Research_articles']

    def add_commons_links(self, commons_filenames):
        self.commons_filenames = commons_filenames

    def add_disallowed_suplementary_files(suplementary_uris):
        self.suplementary_uris = suplementary_uris

    def put():
        augmented_wikitext = self.wikitext
        
        augmented_wikitext += '\n'
        for commons_filename in self.commons_filenames:
            augmented_wikitext += ('\n'+'[[File:'+commons_filename+']]')
        
        augmented_wikitext += '\n'
        for suplementary_uri in self.suplementary_uris:
            augmented_wikitext += ('\n'+'Suplementary file: ['+suplementary_uri+' '+suplementary_uri+']')

        augmented_wikitext += '\n'
        for category in self.categories:
            augmented_wikitext += ('\n'+'[['+category+']]')
 
        page = pywikibot.Page(enws, WSPATH+self.title)        
        page.put(augmented_wikitext)
        
    def make_wikidata_item():
        raise NotImplementedError

