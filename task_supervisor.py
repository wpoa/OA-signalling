from journal_article import journal_article
import os
import pywikibot
import shelve

class directories():
    def __init__(self, data_dir, jats2mw_xsl, wikisource_site, wikisource_basepath):
        self.data_dir = data_dir
        self.jats2mw_xsl = jats2mw_xsl
        self.wikisource_site = wikisource_site
        self.wikisource_basepath = wikisource_basepath

if __name__ == '__main__':
    shelf = shelve.open('journal_shelf', writeback=False)
    
    dirs = directories(data_dir='/home/notconfusing/workspace/OA-signalling/data',
                       jats2mw_xsl='/home/notconfusing/workspace/JATS-to-Mediawiki/jats-to-mediawiki.xsl',
                       wikisource_site=pywikibot.Site('en', 'wikisource'),
                       wikisource_basepath='Wikisource:WikiProject_Open_Access/Programmatic_import_from_PubMed_Central/')

    for doi in ['10.1155/S1110724304404033', '10.1186/1742-4690-2-11', '10.1186/1471-2156-10-59', '10.3897/zookeys.324.5827', '10.1371/journal.pone.0012292', '10.1186/1745-6150-1-19', '10.1371/journal.pbio.0020207', '10.1371/journal.pmed.0050045', '10.1371/journal.pgen.0020220', '10.1371/journal.pbio.1000436']:
        #if doi not in shelf.keys():
        try:
            ja = journal_article(doi=doi, dirs=dirs)
            ja.get_pmcid()
            ja.get_targz()
            ja.extract_targz()
            ja.find_nxml()
            ja.xslt_it()
            ja.get_mwtext_element()
            ja.get_mwtitle_element()
            #ja.push_to_wikisource()
            #ja.push_redirect_wikisource()
            
            shelf[doi] = ja 
            print('success on ', doi)
        except:
            print('failed on', doi)