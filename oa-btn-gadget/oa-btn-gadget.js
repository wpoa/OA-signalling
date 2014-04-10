/*
  Open Access Button integration gadget
*/

(function() {

    function showOAButtonPopup(doi) {
        // ascertain if the bookmarklet has already been called
        var exists = document.getElementById("OAButton");

        if(exists == null) {

            // TODO we won't have a custom user url for wikipedia users but OA button won't work without one
            var url = "https://www.openaccessbutton.org/api/form/page1/689e8f328d9a47c58755c8c80918da57/";

            if(doi) {
                url += "?doi=" + encodeURIComponent(doi);
            }

            // build the control div
            var div = document.createElement("div");
		        div.setAttribute("allowTransparency", "true");
		        div.setAttribute("id", "OAButton");

		        div.style.position = "fixed";
		        div.style.zIndex = "2147483640";
		        div.style.boxSizing = "border-box";
		        div.style.MozBoxSizing = "border-box";
		        div.style.padding = "15px";
		        div.style.background = "white";
		        div.style.height = "100%";
		        div.style.width = "350px";
		        div.style.top = "0";
		        div.style.right = "0";
		        div.style.overflow = "scroll";
		        div.style.overflowX = "hidden";

		        document.body.appendChild(div);

		        // add the close button
		        var closeButton = document.createElement("a");
		        closeButton.setAttribute("href", "javascript:document.getElementById('OAButton').setAttribute('style', 'display:none')");
		        closeButton.setAttribute("id", "closeButton");
		        closeButton.appendChild(document.createTextNode("X"));
		        closeButton.style.zIndex = "2147483641";
		        closeButton.style.position = "relative";
		        closeButton.style.top = "0";

		        div.appendChild(closeButton);

		        // add the iframe
		        var iframe = document.createElement("iframe");
		        iframe.setAttribute("allowTransparency", "true");
		        iframe.setAttribute("src", url);

		        iframe.style.position = "fixed";
		        iframe.style.zIndex = "2147483640";
		        iframe.style.boxSizing = "border-box";
		        iframe.style.MozBoxSizing = "border-box";
		        iframe.style.padding = "15px";
		        iframe.style.borderLeft = "2px #555 dashed";
		        iframe.style.background = "white";
		        iframe.style.height = "100%";
		        iframe.style.width = "350px";
		        iframe.style.bottom = "0";
		        iframe.style.right = "0";

		        div.appendChild(iframe);
	      } else {
		        var div = exists;
		        div.setAttribute("allowTransparency", "true");
		        div.setAttribute("id", "OAButton");

		        div.style.position = "fixed";
		        div.style.zIndex = "2147483640";
		        div.style.boxSizing = "border-box";
		        div.style.MozBoxSizing = "border-box";
		        div.style.padding = "15px";
		        div.style.background = "white";
		        div.style.height = "100%";
		        div.style.width = "350px";
		        div.style.top = "0";
		        div.style.right = "0";
		        div.style.overflow = "scroll";
		        div.style.overflowX = "hidden";
		        div.style.display = "block";

	      }
    }


    var a = $('span.citation');
    var i, oabtn;
    $.each(a, function(i, el) {
        el = $(el)
        // is this a doi?
        if(!el.children("a[title='Digital object identifier']")) {
            console.log("skipping");
            return true; // if not a doi, skip
        }
        var doi = el.children('a.external').html();
        // TODO should check if a "non-oa" css class is set on el
        if(true) { 
            oabtn = document.createElement('a');
            oabtn.setAttribute('href', '#');
            oabtn.innerHTML = "Report paywall";
            $(oabtn).click(function(e) {
                showOAButtonPopup(doi);
                return false;
            })
            el.append(oabtn);
        }
    });
})();

