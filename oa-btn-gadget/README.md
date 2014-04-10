This is an early-stage Open Access button integration gadget.

It adds a short link to the end of citations that have a DOI. The link triggers the OA-button panel via the OA-button API and pre-fills the DOI field.

It uses only the html from a wiki article to find citations and their DOIs. Looking at the mediawiki API I have been unable to find a way to list the citations for a given page, but even if that was possible, we'd have the problem of correlating the wiki markup with the html. It seems that the easiest way to solve the problem is to use css classes to tag citations and DOIs. Right now there is enough info that the script can function, but it could be prettier if the element containing the DOI was tagged explicitly with a unique css class (e.g. class="citation-doi"). 

We will also need to figure out how the OA-button gadget will learn which articles are not open access (and thus need an OA-button link). This could also be as simple as using css classes. The alternative is creating a server-side API.

