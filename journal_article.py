import requests
from bs4 import BeautifulSoup
import wget
import urllib
import tarfile
import os
from subprocess import call
import xml.etree.ElementTree as etree
import pywikibot
from collections import defaultdict
from functools import wraps

class journal_article():
    '''This class represents a journal article 
    and its lifecycle to make it to Wikisource.'''
    def __init__(self, doi, dirs):
        '''journal_articles are represented by dois'''
        if doi.startswith('http://dx.doi.org/'):
            doi_parts = doi.split('http://dx.doi.org/')
            doi = doi_parts[1] 
        self.doi = doi
        self.dirs = dirs
        #a phase is like, have we downloaded it, have we gotten the pmcid, uploaded the images etc.
        self.phase = defaultdict(bool)
    
    def phase_report(self, function):
        @wraps(function)
        def wrapper(*args, **kwargs):
            function_name = function.__name__()
            self.phase[function_name] = True
            return function(*args, **kwargs)
        return wrapper

    @phase_report
    def get_pmcid(self):
        idpayload = {'ids' : self.doi, 'format': 'json'}
        idconverter = requests.get('http://www.pubmedcentral.nih.gov/utils/idconv/v1.0/', params=idpayload)
        records = idconverter.json()['records']
        try:
            if len(records) == 1:
                #since we are supplying a single doi i believe we should be getting only 1 record
                record = records[0]
            else:
                raise ConversionError(message='not just one pmcid for a doi',doi=self.doi)
            self.pmcid = record['pmcid']            
        except:
            raise ConversionError(message='cannot get pmcid',doi=self.doi)

    @phase_report    
    def get_targz(self):
        try:
            archivefile_payload = {'id' : self.pmcid}
            archivefile_locator = requests.get('http://www.pubmedcentral.nih.gov/utils/oa/oa.fcgi', params=archivefile_payload)
            record = BeautifulSoup(archivefile_locator.content)

            # parse response for archive file location
            archivefile_url = record.oa.records.record.find(format='tgz')['href']

            archivefile_name = wget.filename_from_url(archivefile_url)
            complete_path_targz = os.path.join(self.dirs.data_dir, archivefile_name)
            urllib.urlretrieve(archivefile_url, complete_path_targz)
            self.complete_path_targz = complete_path_targz

             # @TODO For some reason, wget hangs and doesn't finish, using
             # urllib.urlretrieve() instead for this for now.
#            archivefile = wget.download(archivefileurl, wget.bar_thermometer)
        except:
            raise ConversionError(message='could not get the tar.gz file from the pubmed', doi=self.doi)

    @phase_report
    def extract_targz(self):
        try:
            directory_name, file_extension = self.complete_path_targz.split('.tar.gz')
            self.dirs.article_dir = directory_name
            tar = tarfile.open(self.complete_path_targz, 'r:gz')
            tar.extractall(self.dirs.data_dir)
        except:
            raise ConversionError(message='trouble extracting the targz', doi=self.doi)
    
    @phase_report
    def find_nxml(self):
        try:
            self.dirs.qualified_article_dir = os.path.join(self.dirs.data_dir, self.dirs.article_dir)
            nxml_files = [file for file in os.listdir(self.dirs.qualified_article_dir) if file.endswith(".nxml")]
            if len(nxml_files) != 1:
                raise ConversionError(message='we need excatly 1 nxml file, no more, no less', doi=self.doi)
            nxml_file = nxml_files[0]
            self.nxml_path = os.path.join(self.dirs.qualified_article_dir, nxml_file)
        except ConversionError as ce:
            raise ce
        except:
            raise ConversionError(message='could not traverse the search dierctory for nxml files', doi=self.doi)

    @phase_report    
    def xslt_it(self):
        try:
            doi_file_name = self.doi + '.mw.xml'
            mw_xml_file = os.path.join(self.dirs.data_dir, doi_file_name)
            doi_file_name_pre_slash = doi_file_name.split('/')[0]
            if doi_file_name_pre_slash == doi_file_name:
                raise ConversionError(message='i think there should be a slash in the doi', doi=self.doi)
            mw_xml_dir = os.path.join(self.dirs.data_dir, doi_file_name_pre_slash)
            if not os.path.exists(mw_xml_dir):
                os.makedirs(mw_xml_dir)
            mw_xml_file_handle = open(mw_xml_file, 'w')
            call_return = call(['xsltproc', self.dirs.jats2mw_xsl, self.nxml_path], stdout=mw_xml_file_handle)
            if call_return == 0: #things went well
                print 'success xslting'
                mw_xml_file_handle.close()
                self.mw_xml_file = mw_xml_file
            else:
                raise ConversionError(message='something went wrong during the xsltprocessing', doi=self.doi)
        except:
            raise ConversionError(message='something went wrong, probably munging the file structure', doi=self.doi)
    
    @phase_report
    def get_mwtext_element(self):
        tree = etree.parse(self.mw_xml_file)
        root = tree.getroot()
        mwtext = root.find('mw:page/mw:revision/mw:text', namespaces={'mw':'http://www.mediawiki.org/xml/export-0.8/'})
        self.wikitext = mwtext.text

    @phase_report
    def get_mwtitle_element(self):
        tree = etree.parse(self.mw_xml_file)
        root = tree.getroot()
        mwtitle = root.find('mw:page/mw:title', namespaces={'mw':'http://www.mediawiki.org/xml/export-0.8/'})
        self.title = mwtitle.text

    @phase_report
    def push_to_wikisource(self):
        page = pywikibot.Page(self.dirs.wikisource_site, self.dirs.wikisource_basepath + self.title)
        comment = "Imported from [[doi:"+self.doi+"]] by recitationbot"
        page.put(newtext=self.wikitext, botflag=True, comment=comment)
        self.wiki_link = page.title(asLink=True)
    
    @phase_report
    def push_redirect_wikisource(self):
        page = pywikibot.Page(self.dirs.wikisource_site, self.dirs.wikisource_basepath + self.doi)
        comment = "Making a redirect"
        redirtext = '#REDIRECT [[' + self.dirs.wikisource_basepath + self.title +']]'
        page.put(newtext=redirtext, botflag=True, comment=comment)

class ConversionError(Exception):
    def __init__(self, message, doi):
        # Call the base class constructor with the parameters it needs
        Exception.__init__(self, message)
        # Now for your custom code...
        self.error_doi = doi