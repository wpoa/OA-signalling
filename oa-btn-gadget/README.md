# Open Access Button MediaWiki Gadget

This is an early-stage Open Access button integration gadget.

It adds a short link to the end of citations that have a DOI. The link triggers the OA-button panel via the OA-button API and pre-fills the DOI field.

It uses only the html from a wiki article to find citations and their DOIs. Looking at the mediawiki API I have been unable to find a way to list the citations for a given page, but even if that was possible, we'd have the problem of correlating the wiki markup with the html. It seems that the easiest way to solve the problem is to use css classes to tag citations and DOIs. Right now there is enough info that the script can function, but it could be prettier if the element containing the DOI was tagged explicitly with a unique css class (e.g. class="citation-doi").

We will also need to figure out how the OA-button gadget will learn which articles are not open access (and thus need an OA-button link). This could also be as simple as using css classes. The alternative is creating a server-side API.

## OA Button Service & API Specification

1. **Bookmarklet** - Currently the OA Button uses a bookmarklet to display a "panel" on the right-hand-side of a web page, enabling a registered user to submit information about where and why they've been "paywalled".
    + **Third Parties** - This is the basic functionality for OA Button, but their team is writing an API in order to offer alternatives to this format of data submission. Namely, third parties (like Wikipedia) should be able to allow their users to send data using an alternative interface than the "panel". This is our goal too.
1. **Source URL vs Referrer URL** Currently the OA Button accepts only one URL, which should point to the paywall. However, working with third parties, additional data is valuable to store and access: the referrer URL, in other words, the URL relevant to the Third Party that leads users to the paywall. For Wikipedia, this case is clear, the referrer would be a particular article that has references of academic content that hit paywalls.

Changes for OA Signalling Project:
* Add unique css class (e.g. class="citation-doi") to the [Template:Cite_DOI](https://en.wikipedia.org/wiki/Tempalte:Cite_DOI).
* Add unique css class for references updated by a citation bot with Open Access license.

Changes for OA Button Project:
* **Anti-Spam** Consider starting to verify email addresses for OA button users.
    * Alternatives include: captcha, etc.
* Authentication API (keys)
    * Need to allow Third Parties to either retrieve or generate API keys in order for end users to submit incident reports.
    * Many ways for this to work, we recommend creating an Authentication API service to generate Application-Level API keys that allow third parties to either generate or retrieve individual user-level API keys for incident report submission.
* Open Access Button Incident API
    * The primary functions needed to work with the OA button are:
        * Incident Report Submission
        * Incident Report Query
    * The aspects of this API are specified below:

List of POST Parameters for Incident API:
* API key
* DOI
* Location
* Description
* Comment
* User name
* User type
    * Could be useful rather to extend this beyond "student" or "researcher" to be "wikipedia" user or "flickr" user.
* Source URL(s)
* Referrer URL(s)

List of GET Parameters for Incident API:
* DOI (or set of DOIs) [optional]
* time_from [optional]
* time_to [optional]
* result_type
    * Options: ('full', 'brief', or 'count')

The 'time_from' and 'time_to' parameters limit the range of response incidents based on time-interval.

'full' Response (for each incident report):
* Time
* Location
* Description
* Comment
* User name
* User type
* Source URL(s)
* Referrer URL(s)

'brief' Response (for each incident report):
* Time
* Location

'count' Response (tally for all incidents):
* Count of incidents
* List of location country, ordered by number of reports

