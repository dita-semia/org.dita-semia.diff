# org.dita-semia.diff
DITA-OT plugin to reate a diff of a DITA document with a previous version of the same document.

You can find here as a sample the comparision result for a bookmap (generated with org.dita-semia.pdf plugin): [_diff-test.pdf](https://github.com/dita-semia/org.dita-semia.diff/blob/master/test/v1.1/out/pdf/_diff-test.pdf)


The plugin consists of two parts:

1. **Resolve-for-Diff** 

	Transtype to store the document in a single file to compare a future version with.

2. **Comparision**

	Preprocess step to compare the current document with the selected earlier version and mark the differences with attributes (e.g. adding the rev attribute with "dsd:added" or "dsd:deleted"). The highlighting will be done with the flagging mechanism afterwards.

The intended use-case it that after publishing a version of your document you also create a a resolved version with the transtype provided by this plugin. 
When publishing a later version you can activate the comparision preprocessing step and a suitable ditaval file for the highlighting and publish it the way you would usually do.

The testing is done with PDF transtype. (For additional features like marking the toc and lot entries the seperate DITA-OT plugin org.dita-semia.pdf is being used.)

It works with single topics as well as with maps and bookmaps. Note, that when a topic has been moved it will be makred as deleted in the previous places and be marked as added in the new place
Referenced images as well as embedded SVG graphics are handled as well: When there is any difference the previous one will be added as deleted and the current one marked as added. So there is no highlighting of the difference within the image.

## Special Features:
- Fully integrated into DITA-OT.
- Handle complete Maps including images.
- Compare during preprocess generated content (e.g. conref, keyref). 
- Created variants based on a single resolved file.
- Compare images.
- Compare words on character level.
- Merge changes in highly modified text.
- Handle added/deleted columns androws in tables.

### Parameters for Resolve-for-Diff

- **dita-semia.resolved4diff.filename**: The filename of the generated zip file. (The file will be stored in the folder as set by output.dir.)

- **dita-semia.resolved4diff.filename.xsl**: The path to an XSLT script to dynamically determine the filename. The input to this script will be the input file after preprocessing. (Will only be used when the parameter dita-semia.resolved4diff.filename has not been set.)  


### Parameters for Comparision

- **dita-semia.diff-prev-url**: The path to the resolved zip file of the earlir version the current document shold be compared with. Setting this parameter activates the comparision.

- **dita-semia.diff.compare.xsl**: The path of the XSLT script to do the comparision. If you want to modify or extend the algorithm you can write your own XSLT script and import the original one.

- **dita-semia.diff-cmp.text-change-wrapper**: The name of the element that will be used to wrap text changes (default: "ph"). 
  
- **dita-semia.diff-cmp.add-attr-name**: The name of the attribute to set for added content (default: "rev").
  
- **dita-semia.diff-cmp.add-attr-val**: The value the marking attribute is set to for added content (default: "dsd:added").
  
- **dita-semia.diff-cmp.del-attr-name**: The name of the attribute to set for deleted content (default: "rev").
  
- **dita-semia.diff-cmp.del-attr-val**: The value the marking attribute is set to for deleted content (default: "dsd:deleted").
  
- **dita-semia.diff.single-indent**: String to be used for indention (default: \tab).
  
- **dita-semia.diff-cmp.protect-text-match-size**: Minimum size of unchanged character sequence that will remain unchanged inependent of the size of changed text before and after (default: 30).
  
- **dita-semia.diff-cmp.protect-text-match-ratio**: Minimal ration between lenght of unchanged text and the length of changed text before and after not to merge the unchanged text with the changed ones (default: 0.2). A value of 0 means that no unchanged text - including single whitespaces - will be merged with changes which is not recommended.
  
- **dita-semia.diff.ditaval-to-xsl.xsl**: The path of the XSLT script to create an XSLT script for the filtering based of the DITAVAL file.
 
- **dita-semia.diff.single-word-compare**: Boolean to specify if changes within single words should be breakon down to the changed letters. If set to false a single changed letter will result in the whole word being marked a sdeleted with the previous spelling and as added with the current spelling. (default: true) 


### Algorithm of Comparision

The comparision consists of two phases:

1. **Normalisation**
 
	Add some attributes required for efficient comparsion:
 
	- **dsd:hash**: A hash code representing the whole element and its content including the attributes. If two elements have the same hash they are assumed to be identical.
	- **dsd:size**: The size of the content. The number of characters within the text content.
	- **dsd:text**: A marker for elements containing text content.
	- **dsd:id**: The original id to be used for id-based matching of elements when tey were modified during the preprocessing (as done for conrefs).	
	
	Additionally elements with text content are prepared (see below for more details). 

2. **Recursive Comparision** 

	The content of document nodes and elements are compared by calculating some kind of longest common subsequence (LCS). 
	The algorithm is an extension of the one described [here](https://en.wikipedia.org/wiki/Longest_common_subsequence_problem):
	
	- Since not single characters are compared but xml nodes the size is not one for all items. So the size of the nodes is also being used. 
	- There is a different level of certainty that two nodes might be the same when they are not identical. So a match score is being used which is 1 for identical nodes and 0 for incomparable nodes.
	
	The algorithm will maximize the products of size and match score.
	Additionally it prefers sequences with longer consecutive matching elements when the have the same score to minimize the frequency of switching between added, deleted and unchanged content in the result.
	
	Comments and processing instructions are completely ignored for the comparision. ut they will be passed through to the result document.


	#### Match Score
	
	The match score is calculated in these steps:
	
	1. elements with different class attribute: 0.0 (not comparable)
	2. identical content (based on @dsd:hash): 1.0
	3. (non-identical) embedded SVG content: 0.0
	4. data elements: 1.0 when @name and @value are identical, 0.0 otherwise
	5. topicref (or derived from it):
		- referencing the same file: 1.0
		- same id of referenced topic: 0.01 (comparable but with lower certainty to hande renamed topic files)
		- same @navtitle: 0.001 (comparable but with lower certainty)
		- no reference but same element name: 0.001 (comparable but with lower certainty to handle e.g. frontmatter)
		- otherwise: 0.0
	6. images: same hash code of referenced file: 1.0, otherwise 0.0
	7. same @id: 1.0
	8. @id attribute present on at least one of the elements but differs: 0.0 (only compare with element having the same id) 
	9. same element (unless in text content): 0.01 (comparable but with lower certainty)
	
	
	#### Processing the Content
	
	After the LCS has been calculated each matching pair will be treaten like this:
	
	1. Insert content (including comments and processinginstructions) between previous and current match marked as added (from current document) or deleted (from previous document).
	2. If the current match is identical (based on @dsd:hash) just copy it.
	3. Otherwise create a copy of the wrapping element with its attributes from the current document and recursively process the content.

	At the end the remaining non-matching content will be inserted as well. 


#### Images

Images are just compared for equalty based on the hash value of the referenced file or the embedded svg content. So when a single pixel has been changed the whole previous image will be marked as deleted and the current one marked as added.


#### Text Content

Elements with text content are identified by containing text nodes not only consisting of white spaces or having the attribute xml:space set to preserve.
Additionally when two elements are compared and only one of them is identified as containing text the other will be treaten the same way.

Unless the attribute xml:space has been set to "preserve" all whitespace content will be collapsed to a single space. And whitespaces at the end will be cut off completely. 

The first stage of comparision will be on word level. This means that the whole text content will be split into tokens while a single token can be
- a combination of letters, digits and underscore 
- any whitespace sequence
- a single punctuation character  

Inline elements with pure wrapping characteristic (like i, u or codeph and without id) are split as well. 
To allow later merge of consecutive identical wrapping elements an attribute @dsd:matchcode is added.

