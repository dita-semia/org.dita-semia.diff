<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema" 
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">
	
	
	<xsl:mode name="splitText"	on-no-match="shallow-copy"/>
	
	
	
	<xsl:template match="text()[not(ancestor::*/@xml:space = 'preserve')][matches(., '^\s+$')]" mode="splitText" priority="10">
		<!--<!-\- insert a single whitespace between two consecutive elements within content that has not been recognized as containing text -\->
		<xsl:if test="preceding-sibling::*[1]/self::*">
			<dsd:text>
				<xsl:attribute name="dsd:hash" 		select="dsd:getHashFromString(' ')"/>
				<xsl:attribute name="dsd:size" 		select="1"/>
				<xsl:attribute name="dsd:mergeCode" select="0"/>
				<xsl:text> </xsl:text>
			</dsd:text>
		</xsl:if>
		<xsl:next-match/>-->
		<dsd:text>
			<xsl:attribute name="dsd:hash" 		select="dsd:getHashFromString(' ')"/>
			<xsl:attribute name="dsd:size" 		select="1"/>
			<xsl:attribute name="dsd:mergeCode" select="0"/>
			<xsl:text> </xsl:text>
		</dsd:text>
	</xsl:template>


	<xsl:template match="text()" mode="splitText">
		<!--
			Allowed groups:
				- combination of letters, digits and underscore 
				- any whitespace sequence
				- single punctuation character 
		-->
		<xsl:variable name="words" as="xs:string*">
			<xsl:analyze-string select="." regex="[\p{{L}}\p{{N}}_]+|[\s]+|[\p{{P}}]" flags="m">
				<xsl:matching-substring>
					<xsl:sequence select="."/>
				</xsl:matching-substring>
				<xsl:non-matching-substring>
					<xsl:sequence select="."/>
				</xsl:non-matching-substring>
			</xsl:analyze-string>
		</xsl:variable>
		<xsl:for-each select="$words">
			<dsd:text>
				<xsl:attribute name="dsd:hash" 		select="dsd:getHashFromString(.)"/>
				<xsl:attribute name="dsd:size" 		select="string-length(.)"/>
				<xsl:attribute name="dsd:mergeCode" select="0"/>
				<xsl:sequence select="."/>
			</dsd:text>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="processing-instruction() | comment()" mode="splitText">
		<dsd:text>
			<xsl:attribute name="dsd:mergeCode" select="0"/>	<!-- should be merged with text nodes -->
			<xsl:attribute name="dsd:skip"/>	<!-- ignore in lcs -->
			<xsl:copy-of select="."/>
		</dsd:text>
	</xsl:template>
	
	<xsl:template match="*[@href]" mode="splitText">
		<xsl:call-template name="atomicInlineElement"/>	<!-- references are atomic -->
	</xsl:template>
	
	<xsl:template match="*[@id]" mode="splitText">
		<xsl:call-template name="atomicInlineElement"/>	<!-- inline elements with id are atomic -->
	</xsl:template>
	
	<xsl:template match="*[@class = $CLASS_PATH_KEY_XREF]" mode="splitText">
		<!-- this element should be transparent for text based comparision -->
		<xsl:apply-templates select="node()" mode="#current"/>
	</xsl:template>
	
	<xsl:template match="element()" mode="splitText">
		<xsl:param name="relevantTextClasses"	as="xs:string*" tunnel="yes"/>

		<xsl:variable name="content" as="node()*">
			<xsl:choose>
				<xsl:when test="node()">
					<xsl:apply-templates select="node()" mode="#current"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text/>	<!-- create empty node to ensure at least one element will be created -->
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="attrHashList" as="xs:integer*">
			<xsl:choose>
				<xsl:when test="exists($relevantTextClasses)">
					<!-- create hash only from relevant class entries -->  
					<xsl:sequence select="for $i in tokenize(@class, '\s+')[. = $relevantTextClasses] return dsd:getHashFromString($i)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="@class" mode="getHash"/>		
				</xsl:otherwise>
			</xsl:choose>
			<xsl:apply-templates select="@id | @href" mode="getHash"/>
		</xsl:variable>

		<!-- use the element name for hash code only when there is no class attribute -->
		<xsl:variable name="mergeCode" 		as="xs:integer"	select="dsd:getHashFromSequence((if (empty(@class)) then name(.) else (), $attrHashList))"/>
		<xsl:variable name="currElement" 	as="element()" 	select="."/>
		
		<xsl:for-each select="$content">
			<xsl:element name="{name($currElement)}">
				<xsl:copy-of select="$currElement/attribute() except $currElement/@dsd:*"/>
				<xsl:copy-of select="$currElement/@dsd:atomic"/>
				<xsl:if test="@dsd:hash">
					<xsl:attribute name="dsd:hash" select="if ($mergeCode = 0) then @dsd:hash else dsd:getHashFromSequence(($mergeCode, @dsd:hash))"/>
				</xsl:if>
				<xsl:attribute name="dsd:size"		select="max((@dsd:size, 1))"/>
				<xsl:attribute name="dsd:mergeCode" select="$mergeCode"/>
				<xsl:sequence select="."/>
			</xsl:element>
		</xsl:for-each>
	</xsl:template>
	
	
	<xsl:template name="atomicInlineElement">
		<xsl:copy>
			<xsl:copy-of select="attribute()"/>
			<xsl:attribute name="dsd:atomic"/>
			<xsl:copy-of select="node()"/>
		</xsl:copy>
	</xsl:template>


	<xsl:template name="unsplitText">
		<xsl:param name="nodes"	as="element()*"/>
		
		<!--<xsl:sequence select="$nodes"/>-->
		<xsl:variable name="mergedInlineElements" as="element()*">
			<xsl:call-template name="mergeInlineElements">
				<xsl:with-param name="nodes" select="$nodes"/>
			</xsl:call-template>	
		</xsl:variable>
		<!--<xsl:sequence select="$mergedInlineElements"/>-->
		<xsl:variable name="result" as="node()*">
			<xsl:call-template name="doTextMarking">
				<xsl:with-param name="nodes" select="$mergedInlineElements"/>
			</xsl:call-template>
		</xsl:variable>
		<!--<xsl:message>unsplitText result: '<xsl:sequence select="$result"/>'</xsl:message>-->
		<xsl:sequence select="$result"/>
	</xsl:template>
	
	
	<xsl:template name="mergeInlineElements">
		<xsl:param name="nodes"	as="element()*"/>

		<xsl:for-each-group select="$nodes" group-adjacent="concat(string(@dsd:mergeCode), exists(self::dsd:text))">
			<xsl:choose>
				<xsl:when test="self::dsd:text">
					<!-- don't merge yet to keep marking -->
					<xsl:copy-of select="current-group()"/>
				</xsl:when>
				<xsl:when test="empty(@dsd:mergeCode)">
					<xsl:copy-of select="current-group()"/>	<!-- content is already merged -->
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy>
						<xsl:copy-of select="attribute() except @dsd:*"/>
						<xsl:variable name="content" as="element()*">
							<xsl:call-template name="mergeInlineElements">
								<xsl:with-param name="nodes" select="current-group()/element()"/>	 
							</xsl:call-template>
						</xsl:variable>
						<xsl:variable name="contentChange" as="xs:string*" select="distinct-values($content!string(@dsd:change))"/>
						<xsl:if test="count($contentChange) = 1">
							<xsl:attribute name="dsd:change" select="$contentChange"/>	<!-- same change for all content -->
						</xsl:if>
						<xsl:sequence select="$content"/>
					</xsl:copy>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each-group>
	</xsl:template>
	
	
	<xsl:template name="doTextMarking">
		<xsl:param name="nodes"	as="element()*"/>
		
		<!--<xsl:message>doTextMarking: <xsl:sequence select="$nodes"/> </xsl:message>-->
		
		<xsl:for-each-group select="$nodes" group-adjacent="string(@dsd:change)">
			<!--<xsl:message>key: '{current-grouping-key()}', nodes: <xsl:sequence select="current-group()"/></xsl:message>-->
			<xsl:choose>

				<xsl:when test="current-grouping-key() = ''">
					<xsl:for-each select="current-group()">
						<xsl:choose>
							<xsl:when test="(self::dsd:text) or (@dsd:change = '') or (@dsd:atomic)">
								<!-- all content is unchanged or atomic -> just copy it -->
								<xsl:apply-templates select="." mode="unwrapText"/>
							</xsl:when>
							<xsl:otherwise>
								<!-- recurse -->
								<xsl:copy>
									<xsl:copy-of select="attribute()"/>
									<xsl:call-template name="doTextMarking">
										<xsl:with-param name="nodes" select="node()"/>	
									</xsl:call-template>
								</xsl:copy>		
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:when>
				
				<xsl:when test="(current-grouping-key() = ($CHANGE_ADDED, $CHANGE_DELETED)) and (current-group()/self::dsd:text/text())">
					<!-- group contains text -> put all adjacent elements of same change in a single wrapper -->
					<xsl:call-template name="wrapChangedText">
						<xsl:with-param name="isAdded"	select="(@dsd:change = $CHANGE_ADDED)"/>
						<xsl:with-param name="content" 	select="current-group()"/>
					</xsl:call-template>
				</xsl:when>
				
				<xsl:when test="(current-grouping-key() = ($CHANGE_ADDED, $CHANGE_DELETED))">
					<!-- mark all individual inline elements -->
					
					<xsl:for-each select="current-group()">
						<xsl:choose>
							<xsl:when test="self::dsd:text">
								<!-- no marking of individual comments or PIs -->
								<xsl:apply-templates select="node()" mode="unwrapText"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:copy>
									<xsl:copy-of select="attribute()"/>
									<xsl:call-template name="changedContent">
										<xsl:with-param name="isAdded"	select="(@dsd:change = $CHANGE_ADDED)"/>
										<xsl:with-param name="content" as="node()*">
											<xsl:apply-templates select="node()" mode="unwrapText"/>
										</xsl:with-param>
									</xsl:call-template>
								</xsl:copy>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:when>
				
				<xsl:otherwise>
					<xsl:message terminate="yes">ERROR: unexpected value for @dsd:change '{current-grouping-key()}'.</xsl:message>
				</xsl:otherwise>
				
			</xsl:choose>
		</xsl:for-each-group>
	</xsl:template>
	

	<xsl:template name="wrapChangedText">
		<xsl:param name="isAdded"	as="xs:boolean"/>
		<xsl:param name="content" 	as="node()*"/>
		
		<!--<xsl:variable name="wrapperName" as="xs:string" select="if (contains($content[1]/parent::*/@class, $CLASS_KEYWORD)) then $WRAPPER_TEXT else $textChangeWrapper"/>-->
		<xsl:element name="{$textChangeWrapper}">
			<xsl:attribute name="class" select="concat('- topic/', $textChangeWrapper, ' ')"/>
			<xsl:call-template name="changedContent">
				<xsl:with-param name="isAdded" select="$isAdded"/>
				<xsl:with-param name="content" as="node()*">
					<xsl:apply-templates select="$content" mode="unwrapText"/>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:element>
	</xsl:template>
	
	
	<xsl:mode name="unwrapText" on-no-match="shallow-copy"/>
	
	<xsl:template match="dsd:text" mode="unwrapText">
		<xsl:copy-of select="node()"/>
	</xsl:template>
	
	
	<xsl:template name="singleWordCompare">
		<xsl:param name="added"		as="node()"/>
		<xsl:param name="deleted"	as="node()"/>
		
		<!--<xsl:message>singleWordCompare - added: '{$added}', deleted: '{$deleted}'</xsl:message>-->
		
		<xsl:choose>
			<xsl:when test="($added/self::dsd:text/text()) and ($deleted/self::dsd:text/text())">
				<xsl:variable name="textParent1" as="document-node()">
					<xsl:call-template name="splitWord">
						<xsl:with-param name="word"	select="$added"/>
					</xsl:call-template>
				</xsl:variable>
				<!--<xsl:message>textParent1: <xsl:sequence select="$textParent1"/></xsl:message>-->
				<xsl:variable name="textParent2" as="document-node()">
					<xsl:call-template name="splitWord">
						<xsl:with-param name="word"	select="$deleted"/>
					</xsl:call-template>
				</xsl:variable>
				<!--<xsl:message>textParent2: <xsl:sequence select="$textParent2"/></xsl:message>-->
				<xsl:variable name="comparedContent" as="node()*">
					<xsl:call-template name="compareContentByLcs">
						<xsl:with-param name="parent1"				select="$textParent1"/>
						<xsl:with-param name="parent2"				select="$textParent2"/>
						<xsl:with-param name="isTextMode"			select="true()" 	tunnel="yes"/>
						<xsl:with-param name="doSingleWordCompare"	select="false()"	tunnel="yes"/>	<!-- avoid recursion -->
					</xsl:call-template>
				</xsl:variable>
				<!--<xsl:message>comparedContent: <xsl:sequence select="$comparedContent"/></xsl:message>-->
				<xsl:sequence select="$comparedContent"/>	<!-- unsplitting will be done later -->
			</xsl:when>
			
			<xsl:when test="$added/@dsd:mergeCode = $deleted/@dsd:merge-code">
				<!-- same wrapper -> merge and recuse into content -->
				<xsl:element name="{name($added)}">
					<xsl:copy-of select="$added/attribute() except $added/@dsd:*"/>
					<xsl:call-template name="singleWordCompare">
						<xsl:with-param name="added" 	select="$added/node()"/>
						<xsl:with-param name="deleted" 	select="$deleted/node()"/>
					</xsl:call-template>
				</xsl:element>
			</xsl:when>
			
			<xsl:otherwise>
				<!-- not comparable -> just put as added/deleted -->
				<xsl:apply-templates select="$added" 	mode="added"/>
				<xsl:apply-templates select="$deleted" 	mode="deleted"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="splitWord" as="document-node()">
		<xsl:param name="word"	as="xs:string"/>
		
		<xsl:document>
			<xsl:analyze-string select="$word" regex="." flags="s">
				<xsl:matching-substring>
					<dsd:text dsd:size="1" dsd:hash="{.}">
						<xsl:sequence select="."/>
					</dsd:text>
				</xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:document>
	</xsl:template>

</xsl:stylesheet>
