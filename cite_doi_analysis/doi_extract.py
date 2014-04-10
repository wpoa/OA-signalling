from mw import xml_dump
import datetime
import mwparserfromhell
import json

files = ["enwiki-20140304-pages-articles-multistream.xml"]

stime = datetime.datetime.now()

print('starting at', stime)

valid_page_titles = json.load(open('doi_page_titles.json', 'r'))

def page_info(dump, path):
    for page in dump:
        cite_dois = list()
        journal_dois = list()
        if page.namespace == 0:
            if page.title in valid_page_titles:
                print(page.title)
                revisions = list(page)
                if len(revisions) != 1:
                    raise ValueError
                else:
                    latest_revision = revisions[0]
                    wikicode = mwparserfromhell.parse(latest_revision.text)
                    for template in wikicode.filter_templates():
                        if template.name.lower().replace('_',' ') == 'cite doi':
                            for param in template.params:
                                cite_dois.append(param)
            yield(page.title, page.id, {'cite_dois':cite_dois, 'journal_dois':journal_dois})
         

outfile = open('doi_list.txt', 'w')

for page_title, page_id, doi_dict in xml_dump.map(files, page_info):
    print(' pageid', page_id, ' page title ', page_title , ' doi_dict', doi_dict)
    #if int(page_id) > 10000:
    #    break
    if doi_dict['cite_dois']:
        for doi in doi_dict['cite_dois']:
            outfile.write(str(page_title) + '\t' + str(doi)+ '\n')
    if doi_dict['journal_dois']:
        for doi in doi_dict['journal_dois']:
            outfile.write('cite journal ---- ' + str(doi) + '\n')

outfile.close()

etime = datetime.datetime.now()
print(etime)
print('took ', (etime - stime))
