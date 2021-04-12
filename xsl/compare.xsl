<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema" 
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">
	
	
	<xsl:param name="tmpUriSuffix" 			as="xs:string" 	select="'.tmp'"/>
	<xsl:param name="prevUri" 				as="xs:string"	select="''"/>
	<xsl:param name="delTopicListFile" 		as="xs:string" 	select="'dsd-delditatopic.list'"/>
	<xsl:param name="jobFile" 				as="xs:string" 	select="'.job.xml'"/>
	<xsl:param name="textChangeWrapper"	 	as="xs:string"	select="'ph'"/>
	<xsl:param name="addAttrName" 			as="xs:string"	select="'rev'"/>
	<xsl:param name="addAttrVal" 			as="xs:string"	select="'dsd:added'"/>
	<xsl:param name="delAttrName" 			as="xs:string"	select="'rev'"/>
	<xsl:param name="delAttrVal" 			as="xs:string"	select="'dsd:deleted'"/>
	<xsl:param name="singleIndent" 			as="xs:string" 	select="'&#x09;'"/>
	<xsl:param name="protectTextMatchSize"	as="xs:integer" select="30"/>
	<xsl:param name="protectTextMatchRatio"	as="xs:double" 	select="0.3"/>
	<xsl:param name="doSingleWordCompare"	as="xs:boolean" select="true()"/>
	<xsl:param name="relevantTextClasses"	as="xs:string" 	select="'hi-d/i, hi-d/b, hi-d/u, pr-d/codeph'"/>
	


	<xsl:include href="common/consts.xsl"/>
	<xsl:include href="common/base-uri.xsl"/>
	<xsl:include href="common/getHashSize.xsl"/>
	<xsl:include href="common/extensionFunctions.xsl"/>
	<xsl:include href="compare/lcs.xsl"/>
	<xsl:include href="compare/matchScore.xsl"/>
	<xsl:include href="compare/processMatch.xsl"/>
	<xsl:include href="compare/text.xsl"/>
	<xsl:include href="compare/tables.xsl"/>
	<xsl:include href="compare/marking.xsl"/>
	<xsl:include href="compare/write.xsl"/>
	
	
	<xsl:template match="/">
		
		<xsl:variable name="prevUriNormalized" as="xs:string" select="replace($prevUri, '[\\]', '/')"/>
		
		<xsl:call-template name="compareDoc">
			<xsl:with-param name="doc1"					select="."/>
			<xsl:with-param name="doc2Uri"				select="xs:anyURI($prevUriNormalized)"/>
			<xsl:with-param name="outputUri"			select="xs:anyURI(concat(dsd:base-uri(.), $tmpUriSuffix))"/>
			<xsl:with-param name="isRoot"				select="true()"/>
			<xsl:with-param name="doSingleWordCompare"	select="$doSingleWordCompare" 						tunnel="yes"/>
			<xsl:with-param name="relevantTextClasses"	select="tokenize($relevantTextClasses, '[,\s]+')" 	tunnel="yes"/>
			
		</xsl:call-template>
	</xsl:template>
	
	
	<xsl:template name="compareDoc">
		<xsl:param name="doc1"			as="document-node()"/>
		<xsl:param name="doc2Uri"		as="xs:anyURI?"/>
		<xsl:param name="outputUri"		as="xs:anyURI"/>
		<xsl:param name="isRoot"		as="xs:boolean"			select="false()"/>
		<xsl:param name="rootResult"	as="document-node()?"	tunnel="yes"/>
		
		<xsl:variable name="doc2" as="document-node()?" select="if (doc-available($doc2Uri)) then doc($doc2Uri) else ()"/>
		
		<xsl:choose>
			<xsl:when test="empty($doc2)">
				<xsl:message terminate="yes">ERROR: file to compare with could not be loaded: {$doc2Uri}</xsl:message>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>Comparing file {dsd:base-uri($doc1)} with {$doc2Uri} ...</xsl:message>
				<xsl:variable name="result" as="document-node()">
					<xsl:apply-templates select="$doc1" mode="processMatch">
						<xsl:with-param name="matchNode" 				select="$doc2"/>
						<xsl:with-param name="protectTextMatchSize"		select="$protectTextMatchSize" 	tunnel="yes"/>
						<xsl:with-param name="protectTextMatchRatio"	select="$protectTextMatchRatio" tunnel="yes"/>
					</xsl:apply-templates>
				</xsl:variable>
				<xsl:apply-templates select="$result" mode="write">
					<xsl:with-param name="outputUri"	select="$outputUri"/>
					<xsl:with-param name="singleIndent" select="$singleIndent" tunnel="yes"/>
					<xsl:with-param name="rootResult" 	select="if ($isRoot) then $result else $rootResult" tunnel="yes"/>
				</xsl:apply-templates>
				<xsl:if test="$isRoot">
					<xsl:call-template name="writeDelTopics">
						<xsl:with-param name="compareResult" select="$result"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="document-node() | element()" mode="compareContent">
		<xsl:param name="parent2"	as="node()"/>
		
		<xsl:call-template name="compareContent">
			<xsl:with-param name="parent1" select="."/>
			<xsl:with-param name="parent2" select="$parent2"/>
		</xsl:call-template>
	</xsl:template>
	
	
	<xsl:template name="compareContent">
		<xsl:param name="parent1"		as="node()"/>
		<xsl:param name="parent2"		as="node()"/>
		<xsl:param name="isTextMode"	as="xs:boolean" select="false()" tunnel="yes"/>
		
		<!--<xsl:message>compareContent ({$isTextMode}): {name($parent1)}, {name($parent2)}</xsl:message>-->
		
		<xsl:choose>
			
			<xsl:when test="dsd:isEmpty($parent1, $isTextMode) or dsd:isEmpty($parent2, $isTextMode)">
				<!--<xsl:message>addedDeleted:</xsl:message>
				<xsl:message select="$parent1"/>
				<xsl:message>xxxxxxxxxxxxxxxxxxx</xsl:message>
				<xsl:message select="$parent2"/>
				<xsl:message>xxxxxxxxxxxxxxxxxxx</xsl:message>-->
				<xsl:call-template name="addedDeleted">
					<xsl:with-param name="added" 	select="$parent1/node()"/>
					<xsl:with-param name="deleted"	select="$parent2/node()"/>
				</xsl:call-template>
			</xsl:when>

			<xsl:when test="($parent1/@dsd:text) or ($parent2/@dsd:text) or ($isTextMode)">
				<!--<xsl:message>compareContent on {name($parent1)} ({$isTextMode}): p1-text: {$parent1/@dsd:text}, p2-text: {$parent2/@dsd:text}</xsl:message>-->	
				<xsl:variable name="textParent1" as="element()">
					<dsd:textParent>
						<xsl:attribute name="xml:base" select="dsd:base-uri($parent1)"/>
						<xsl:apply-templates select="$parent1/node()" mode="splitText"/>
					</dsd:textParent>
				</xsl:variable>
				<xsl:variable name="textParent2" as="element()">
					<dsd:textParent>
						<xsl:attribute name="xml:base" select="dsd:base-uri($parent2)"/>
						<xsl:apply-templates select="$parent2/node()" mode="splitText"/>
					</dsd:textParent>
				</xsl:variable>
				<xsl:variable name="comparedContent" as="node()*">
					<xsl:call-template name="compareContentByLcs">
						<xsl:with-param name="parent1" 		select="$textParent1"/>
						<xsl:with-param name="parent2" 		select="$textParent2"/>
						<xsl:with-param name="isTextMode"	select="true()" 		tunnel="yes"/>
					</xsl:call-template>
				</xsl:variable>
				<!--<xsl:message>-\-\-\-\-\-\-\-</xsl:message>
				<xsl:message select="$textParent1"/>
				<xsl:message select="$textParent2"/>
				<xsl:message select="$comparedContent"/>-->

				<xsl:call-template name="unsplitText">
					<xsl:with-param name="nodes" select="$comparedContent"/>
				</xsl:call-template>
			</xsl:when>
			
			<xsl:otherwise>
				<xsl:call-template name="compareContentByLcs">
					<xsl:with-param name="parent1" select="$parent1"/>
					<xsl:with-param name="parent2" select="$parent2"/>
				</xsl:call-template>
			</xsl:otherwise>
			
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:function name="dsd:isEmpty" as="xs:boolean">
		<xsl:param name="node" 			as="node()"/>
		<xsl:param name="isTextMode" 	as="xs:boolean"/>
		
		<xsl:sequence select="if (($isTextMode) or ($node/@dsd:text)) then empty($node/(text() | element())) else empty($node/element())"/>
	</xsl:function>
	
	
	<xsl:template name="compareContentByLcs">
		<xsl:param name="parent1"		as="node()"/>
		<xsl:param name="parent2"		as="node()"/>
		
		<xsl:variable name="lcs" as="element(lcs)">
			<xsl:call-template name="lcs">
				<xsl:with-param name="parent1" select="$parent1"/>
				<xsl:with-param name="parent2" select="$parent2"/>
			</xsl:call-template>
		</xsl:variable>
		<!--<xsl:message select="$lcs"/>-->
		<xsl:call-template name="processContent">
			<xsl:with-param name="parent1" 	select="$parent1"/>
			<xsl:with-param name="parent2" 	select="$parent2"/>
			<xsl:with-param name="lcs1" 	select="tokenize($lcs/@s1, '\s')!xs:integer(.)"/>
			<xsl:with-param name="lcs2" 	select="tokenize($lcs/@s2, '\s')!xs:integer(.)"/>
			<xsl:with-param name="index"	select="1"/>
		</xsl:call-template>
	</xsl:template>
	
	
	<xsl:template name="processContent">
		<xsl:param name="parent1"	as="node()"/>
		<xsl:param name="parent2"	as="node()"/>
		<xsl:param name="lcs1"		as="xs:integer*"/>
		<xsl:param name="lcs2"		as="xs:integer*"/>
		<xsl:param name="prevPos1"	as="xs:integer" 	select="0"/>
		<xsl:param name="prevPos2"	as="xs:integer" 	select="0"/>
		<xsl:param name="index"		as="xs:integer"		select="1"/>
		
		<xsl:variable name="currPos1"	as="xs:integer?" select="$lcs1[$index]"/>
		<xsl:variable name="currPos2"	as="xs:integer?" select="$lcs2[$index]"/>
		<!--<xsl:message >index: {$index}, currPos1: {$currPos1}, currPos2: {$currPos2}, parent1: {generate-id($parent1)}</xsl:message>-->
		
		<xsl:choose>
			<xsl:when test="$currPos1">
				
				<!-- copy not matching nodes between last match and this one -->
				<xsl:call-template name="addedDeleted">
					<xsl:with-param name="added" 	select="$parent1/node()[(position() gt $prevPos1) and (position() lt $currPos1)]"/>
					<xsl:with-param name="deleted"	select="$parent2/node()[(position() gt $prevPos2) and (position() lt $currPos2)]"/>
				</xsl:call-template>
								
				<!--<xsl:message>processContent: <xsl:value-of select="name($parent1)"/>/<xsl:value-of select="name($parent1/node()[$currPos1])"/>,<xsl:value-of select="$prevPos1"/> : <xsl:value-of select="name($parent2)"/>/<xsl:value-of select="name($parent2/node()[$currPos2])"/>,<xsl:value-of select="$prevPos2"/></xsl:message>
				<xsl:message select="$parent1"/>-->
					
				<!-- handle matching node -->
				<xsl:variable name="matchResult" as="node()?">
					<xsl:apply-templates select="$parent1/node()[$currPos1]" mode="processMatch">
						<xsl:with-param name="matchNode" select="$parent2/node()[$currPos2]"/>
					</xsl:apply-templates>
				</xsl:variable>
				<xsl:sequence select="$matchResult"/>
				<!--<xsl:message>matchResult: <xsl:sequence select="$matchResult"/></xsl:message>-->
				
				
				<!-- recurse -->
				<xsl:call-template name="processContent">
					<xsl:with-param name="parent1" 	select="$parent1"/>
					<xsl:with-param name="parent2" 	select="$parent2"/>
					<xsl:with-param name="lcs1" 	select="$lcs1"/>
					<xsl:with-param name="lcs2" 	select="$lcs2"/>
					<xsl:with-param name="prevPos1"	select="$currPos1"/>
					<xsl:with-param name="prevPos2"	select="$currPos2"/>
					<xsl:with-param name="index"	select="$index + 1"/>
				</xsl:call-template>
				
			</xsl:when>
			<xsl:otherwise>
				
				<!--<xsl:message>addedDeleted {generate-id($parent1)}, count {count($parent1/node())}, $prevPos1 {$prevPos1}</xsl:message>-->
				
				<!-- copy remaining content -->
				<xsl:call-template name="addedDeleted">
					<xsl:with-param name="added" 	select="$parent1/node()[position() gt $prevPos1]"/>
					<xsl:with-param name="deleted" 	select="$parent2/node()[position() gt $prevPos2]"/>
				</xsl:call-template>
				
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	
	<xsl:template name="addedDeleted">
		<xsl:param name="added"					as="node()*"/>
		<xsl:param name="deleted"				as="node()*"/>
		<xsl:param name="isTextMode"			as="xs:boolean" select="false()" 	tunnel="yes"/>
		<xsl:param name="doSingleWordCompare"	as="xs:boolean" select="true()" 	tunnel="yes"/>

		<!--<xsl:message>added: <xsl:sequence select="$added"></xsl:sequence></xsl:message>
		<xsl:message>deleted: <xsl:sequence select="$deleted"></xsl:sequence></xsl:message>-->
		
		<xsl:choose>
			<xsl:when test="not($isTextMode)">
				<!-- text for indention will be added on write stage -->
				<xsl:apply-templates select="$added[not(self::text())]" 	mode="added"/>
				<xsl:apply-templates select="$deleted[not(self::text())]" 	mode="deleted"/>		
			</xsl:when>
			<xsl:when test="($doSingleWordCompare) and (count($added) = 1) and (count($deleted) = 1) and not($added/@dsd:atomic) and not($deleted/@dsd:atomic)">
				<xsl:call-template name="singleWordCompare">
					<xsl:with-param name="added"	select="$added"/>
					<xsl:with-param name="deleted"	select="$deleted"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="$added" 	mode="added"/>
				<xsl:apply-templates select="$deleted" 	mode="deleted"/>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	
	
	<xsl:template name="writeDelTopics">
		<xsl:param name="compareResult" as="document-node()"/>
		
		<xsl:variable name="delTopicList" as="xs:string*">
			<xsl:apply-templates select="$compareResult" mode="getDelTopicList"/>
		</xsl:variable>
		<xsl:if test="exists($delTopicList)">
			<xsl:variable name="baseUri" as="xs:anyURI" select="xs:anyURI(replace($delTopicListFile, ' ', '%20'))"/>
			<!--<xsl:message>delTopicListFile: {$delTopicListFile}, baseUri: {$baseUri}</xsl:message>-->
			<xsl:result-document href="{$delTopicListFile}" method="text">
				<xsl:for-each select="$delTopicList">
					<xsl:text>&#x0A;</xsl:text>
					<xsl:value-of select="replace(dsd:relativizeHref(., $baseUri), '%20', ' ')"/>
				</xsl:for-each>
			</xsl:result-document>
			<xsl:variable name="jobFileNormalized" as="xs:string" select="replace($jobFile, '\\', '/')"/>
			<xsl:result-document href="{$jobFileNormalized}{$tmpUriSuffix}" method="xml" indent="yes">
				<xsl:apply-templates select="doc($jobFileNormalized)" mode="addDelTopicList">
					<xsl:with-param name="delTopicList" select="$delTopicList"	tunnel="yes"/>
					<xsl:with-param name="baseUri" 		select="$baseUri" 		tunnel="yes"/>
				</xsl:apply-templates>
			</xsl:result-document>
		</xsl:if>
	</xsl:template>

	
	<xsl:mode name="getDelTopicList" on-no-match="shallow-skip"/>
	
	<xsl:template match="*[contains(@class, $CLASS_TOPICREF)][ancestor-or-self::*/@dsd:change = $CHANGE_DELETED]/@href" mode="getDelTopicList">
		<xsl:value-of select="."/>
	</xsl:template>
	
	
	<xsl:mode name="addDelTopicList" on-no-match="shallow-copy"/>
	
	<xsl:template match="job/files" mode="addDelTopicList">
		<xsl:param name="delTopicList" 	as="xs:string*" tunnel="yes"/>
		<xsl:param name="baseUri" 		as="xs:anyURI" 	tunnel="yes"/>
		
		<xsl:copy>
			<xsl:apply-templates select="attribute() | node()" mode="#current"/>
			<xsl:for-each select="$delTopicList">
				<xsl:variable name="relUri" as="xs:string" select="dsd:relativizeHref(., $baseUri)"/>
				<file>
					<xsl:attribute name="src"		select="."/>
					<xsl:attribute name="uri"		select="$relUri"/>
					<xsl:attribute name="path"		select="$relUri"/>
					<xsl:attribute name="result"	select="."/>
					<xsl:attribute name="format"	select="'dita'"/>
					<xsl:attribute name="target"	select="true()"/>
				</file>
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>
