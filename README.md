# About

This repo is part of the [OA Signalling project](https://en.wikipedia.org/wiki/Wikipedia:WikiProject_Open_Access/Signalling_OA-ness) that aims to build a system to signal whether references cited on Wikipedia are free to reuse.

Cited sources form an integral part of both scholarly communication and Wikipedia. They are meant to support statements made in the citing articles and invite readers to dive deeper into the subject at hand. 

Enhancing the accessibility of cited sources thus contributes to the educational mission of the Wikimedia community. Many sources, however, are not accessible to the average Wikipedia reader due to paywalls in front of them, and many of those that are free to read can not be freely reused. 

For scholarly articles, a system that provides article-level licensing information is currently being developed by DOAJ and CrossRef. This resource could be tapped for signalling the openness of references cited on Wikipedia. 

It is the aim of this project to provide the technical infrastructure that would enable that, and to engage the Wikimedia and Open Access communities towards implementing it.

# Workflow

Here is a short version of the envisaged workflow (components central to the project are marked in bold):

 1. listen to RecentChanges feed across all Wikimedia wikis (cf. [event-data-wikipedia-agent](https://github.com/CrossRef/event-data-wikipedia-agent))
 2. filter by bibliographic identifier for papers (currently only DOI, long-term also PubMed ID, PMC ID, arXiv ID, JSTOR ID and perhaps others)
 3. check whether paper was cited or uncited (all steps until here are included in [CrossRef's live stream of DOI citations in Wikipedia](http://wikipedia.labs.crossref.org/))
 4. handle potential vandalism/ spam, e.g. via [Revision scoring](https://github.com/wpoa/OA-signalling/issues/114)
 5. pull paper metadata from suitable source (e.g. from CrossRef/ DataCite for DOIs); [Recitation bot](https://github.com/wpoa/recitation-bot) does that, and so does [Source, M.D.](https://tools.wmflabs.org/sourcemd/?)
 6. **check whether that paper is available on Wikisource** (initially only English, long-term other languages too)
   1. if so, **check proper representation of paper and its metadata** on Wikisource (as well as on Commons, Wikidata and Wikipedia) and in case of inconsistencies, notify someone (e.g. the original citer and/ or a relevant WikiProject, or simply a tracking page)
   2. if not, **check whether that paper is available in JATS** (currently only via PubMed Central, but long-term from anywhere); Recitation bot does that
      1. if so, **check licensing of the paper**
         1. if license is open, **[convert paper's JATS XML to MediaWiki XML](https://github.com/wpoa/JATS-to-Mediawiki)**
            1. **upload full text to Wikisource** (Recitation bot does that &mdash; see [contribution history](https://en.wikisource.org/wiki/Special:Contributions/Recitation-bot), [on-wiki page list](https://en.wikisource.org/wiki/Wikisource:WikiProject_Open_Access/Programmatic_import_from_PubMed_Central#Subpages_of_this_page) and [tracking categories](https://github.com/wpoa/recitation-bot/issues/49))
               1. **check for consistency with original** (perhaps via [fuzzy anchoring](https://github.com/wpoa/OA-signalling/issues/115)?)
            2. **upload images and media to Wikimedia Commons** (requires duplicate detection - many images and videos already there; Recitation bot does that too &mdash; see [contribution history](https://commons.wikimedia.org/wiki/Special:Contributions/Recitation-bot) and [tracking categories](https://github.com/wpoa/recitation-bot/issues/49); there is an [unresolved issue with high-res images](https://github.com/wpoa/JATS-to-Mediawiki/issues/20)); for video or audio files (covered by the [Open Access Media Importer](https://commons.wikimedia.org/wiki/User:Open_Access_Media_Importer_Bot)), put a copy of the original file onto the [Schnittserver](https://de.wikipedia.org/wiki/Wikipedia:WikiTV/Schnittserver/Specification)
         2. if license is not open, notify OA Button (perhaps via [OABOT](https://en.wikipedia.org/wiki/Wikipedia:The_Wikipedia_Library/OABOT)?)
   3. **[start or update the Wikidata items](https://www.wikidata.org/wiki/Wikidata:WikiProject_Source_MetaData/Source,_M.D./Tests) for paper and/ or [authors](https://tools.wmflabs.org/wikidata-game/distributed/#game=9)** as necessary, perhaps even for references cited in the paper ([bib2wikidata](https://github.com/mitar/bib2wikidata) can upload CSL)
7. check whether the initial citation that was identified through the RecentChanges stream is **[pulling bibliographic metadata from Wikidata](https://www.wikidata.org/wiki/Module:Cite)**
   1. if so, purge page to refresh display of citation information
   2. if not, update original citation with licensing/ [OA Button info](https://github.com/wpoa/oa-btn-gadget) and links to Wikisource, Commons, Wikidata, as necessary
8. keep track of revisions of cited references via [CrossMark](http://www.crossref.org/crossmark/) and notify someone of retractions etc.
9. keep track of further citations (of the same cited reference) from within and beyond Wikimedia, e.g. via the [DOI Event Tracker](http://blog.crossref.org/2015/09/det-poised-for-launch.html) and notify someone (including the **[Cite-o-Meter](https://tools.wmflabs.org/cite-o-meter/)**)

Most of the components of this workflow do already exist but need some tweaking or brushing to fit our purposes better or to turn the pieces into a pipeline.  
