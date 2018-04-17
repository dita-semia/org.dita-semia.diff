<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema"
	xmlns:svg	= "http://www.w3.org/2000/svg"
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">

	<xsl:variable name="KEY_MATCH_HREF" as="xs:string" select="'MatchHref'" static="yes"/>

	<xsl:key _name="{$KEY_MATCH_HREF}" match="*[@dsd:matchHref]" use="@dsd:matchHref"/>

	<xsl:mode name="write" 				on-no-match="shallow-copy" />
	<xsl:mode name="writeSpacePreserve" on-no-match="shallow-copy"/>
	
	<xsl:template match="element()[(@xml:space = 'preserve') or (@dsd:text = true())]" mode="write">
		<xsl:param name="outputUri" 	as="xs:anyURI"/>
		
		<xsl:copy copy-namespaces="false">
			<xsl:apply-templates select="attribute(), node()" mode="writeSpacePreserve">
				<xsl:with-param name="outputUri" 	select="$outputUri"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	
	
	<xsl:template match="element()" mode="write">
		<xsl:param name="outputUri" 	as="xs:anyURI"/>
		<xsl:param name="indent" 		as="xs:string?"/>
		<xsl:param name="singleIndent" 	as="xs:string"	select="'&#x09;'" tunnel="yes"/>
		
		<xsl:copy copy-namespaces="false">
			<xsl:apply-templates select="attribute()" mode="#current">
				<xsl:with-param name="outputUri" select="$outputUri"/>
			</xsl:apply-templates>
			
			<!-- don't do indentation when there is already text content --> 
			<xsl:variable name="doIndent" as="xs:boolean" select="empty(text())"/>
			
			<xsl:for-each select="node()"> 
				<xsl:if test="$doIndent">
					<xsl:value-of select="concat('&#xA;', $indent, $singleIndent)"/>
				</xsl:if>
				<xsl:apply-templates select="." mode="#current">
					<xsl:with-param name="outputUri" 	select="$outputUri"/>
					<xsl:with-param name="indent" 		select="concat($indent, $singleIndent)"/>
				</xsl:apply-templates>
			</xsl:for-each>
			<xsl:if test="(node()) and ($doIndent)">
				<xsl:value-of select="concat('&#xA;', $indent)"/>
			</xsl:if>
		</xsl:copy>
	</xsl:template>
	
	
	<xsl:template match="document-node()" mode="write">
		<xsl:param name="outputUri" as="xs:anyURI"/>
		
		<xsl:copy>
			<xsl:for-each select="node()">
				<xsl:value-of select="if (position() > 0) then '&#xA;' else ''"/>
				<xsl:apply-templates select="." mode="#current">
					<xsl:with-param name="outputUri" select="$outputUri"/>
				</xsl:apply-templates>
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>


	<xsl:template match="@dsd:*" mode="write writeSpacePreserve">
		<!-- filter these attributes -->
	</xsl:template>
	
	<xsl:template match="element()" mode="writeSpacePreserve">
		<xsl:param name="outputUri" as="xs:anyURI"/>
		
		<xsl:copy copy-namespaces="false">
			<xsl:apply-templates select="attribute(), node()" mode="#current">
				<xsl:with-param name="outputUri" select="$outputUri"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	
	
	<xsl:template match="*[contains(@class, $CLASS_TOPICREF)][not(string(@href) = '')]" mode="write" priority="10">
		<xsl:param name="outputUri" as="xs:anyURI"/>
		<xsl:param name="indent" 	as="xs:string?"/>
		
		<xsl:next-match>
			<xsl:with-param name="outputUri" 	select="$outputUri"/>
			<xsl:with-param name="indent"		select="$indent"/>
		</xsl:next-match>
		
		<!--<xsl:message>href: {@href}, base-uri: {ancestor-or-self::*/@xml:base}</xsl:message>-->
		<xsl:variable name="refUri"	as="xs:anyURI" 			select="resolve-uri(@href, base-uri(.))"/>
		<xsl:variable name="refDoc"	as="document-node()?" 	select="if (doc-available($refUri)) then doc($refUri) else()"/>
		<xsl:variable name="dstUri"	as="xs:anyURI" 			select="xs:anyURI(concat($refUri, $tmpUriSuffix))"/>
		
		<xsl:choose>
			<xsl:when test="empty($refDoc)">
				<xsl:message>ERROR: referenced file could not be loaded: {$refUri}</xsl:message>
			</xsl:when>
			
			<xsl:when test="exists(ancestor-or-self::*/@dsd:change)">
				<xsl:message>Marking file as {ancestor-or-self::*/@dsd:change}: {$refUri}</xsl:message>
				<xsl:variable name="isAdded" as="xs:boolean" select="ancestor-or-self::*/@dsd:change = $CHANGE_ADDED"/>
				<xsl:call-template name="writeDoc">
					<xsl:with-param name="uri"		select="$dstUri"/>
					<xsl:with-param name="content"	as="node()*">
						<xsl:for-each select="$refDoc/node()">
							<xsl:copy>
								<xsl:if test="self::element()">
									<xsl:apply-templates select="attribute()" mode="#current">
										<xsl:with-param name="outputUri" select="$dstUri"/>
									</xsl:apply-templates>
									<xsl:call-template name="changedContent">
										<xsl:with-param name="isAdded" select="$isAdded"/>
										<xsl:with-param name="content" as="node()*">
											<xsl:apply-templates select="node()" mode="#current">
												<xsl:with-param name="outputUri" select="$dstUri"/>
											</xsl:apply-templates>
										</xsl:with-param>
									</xsl:call-template>
								</xsl:if>
							</xsl:copy>
						</xsl:for-each>						
					</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			
			<xsl:when test="@dsd:matchHref">
				<xsl:call-template name="writeDoc">
					<xsl:with-param name="uri"		select="$dstUri"/>
					<xsl:with-param name="content"	as="node()*">
						<xsl:call-template name="compareDoc">
							<xsl:with-param name="doc1"			select="$refDoc"/>
							<xsl:with-param name="doc2Uri"		select="@dsd:matchHref"/>
							<xsl:with-param name="outputUri"	select="$dstUri"/>
						</xsl:call-template>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			
			<xsl:when test="@dsd:unchanged">
				<xsl:message>No changes in file {$refUri}</xsl:message>
			</xsl:when>
			
			<xsl:otherwise>
				<xsl:message terminate="yes">ERROR: unexpected behavior (<xsl:sequence select="."/>)</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="*[ancestor-or-self::*/@dsd:change = $CHANGE_DELETED][contains(@class, $CLASS_IMAGE)]/@href[starts-with(., 'file:/')]" mode="write writeSpacePreserve" priority="20">
		<!-- keep absolute URI -->
		<xsl:copy/>
	</xsl:template>
	
	<xsl:template match="@href[starts-with(., 'file:')]" mode="write writeSpacePreserve" priority="10">
		<xsl:param name="outputUri" 	as="xs:anyURI"/>
		<xsl:param name="rootResult" 	as="document-node()" tunnel="yes"/>

		<xsl:variable name="fixedHref"	as="xs:string"	select="dsd:getFixedHref(., $rootResult)"/>
		
		<!--<xsl:if test="not(string(.) = $fixedHref)">
			<xsl:message>redirect href "{dsd:relativizeHref(., $outputUri)}" to "{dsd:relativizeHref($fixedHref, $outputUri)}"</xsl:message>
		</xsl:if>-->

		<!-- make references relative again -->
		<xsl:attribute name="href" select="dsd:relativizeHref($fixedHref, $outputUri)"/>
	</xsl:template>


	<xsl:template match="*[contains(@class, ' topic/xref ')]/processing-instruction('ditaot')[. = $DITAOT_PI_GENTEXT]" mode="write writeSpacePreserve">
		<xsl:choose>
			<xsl:when test="parent::*/*">
				<!-- the link text doesn't contain pure text due to added change markers -> change to usertext to support highlighting -->
				<xsl:processing-instruction name="ditaot" select="$DITAOT_PI_USERTEXT"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:function name="dsd:getFixedHref" as="xs:string?">
		<xsl:param name="href"			as="xs:string?"/>
		<xsl:param name="rootResult" 	as="document-node()?"/>
		
		<xsl:choose>
			<xsl:when test="exists($href) and exists($rootResult)">
				<xsl:variable name="hrefParts" as="xs:string*" select="tokenize($href, '#')"/>
				
				<!-- if the href links to an old topic that has been merged with a new one redirect to new topic -->
				<xsl:variable name="refMatch" 	as="element()?" select="key($KEY_MATCH_HREF, $hrefParts[1], $rootResult)[1]"/>
				<xsl:variable name="fixedHref"	as="xs:string"	select="if ($refMatch) then string-join((resolve-uri($refMatch/@href, base-uri($refMatch)), $hrefParts[2]), '#') else $href"/>
				
				<xsl:sequence select="$fixedHref"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="$href"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	
	<xsl:template name="writeDoc">
		<xsl:param name="uri"		as="xs:anyURI"/>
		<xsl:param name="content" 	as="node()*"/>
		<xsl:param name="writeDocs"	as="xs:boolean"	select="true()" tunnel="yes"/>
		
		<xsl:if test="$writeDocs">
			<xsl:result-document href="{$uri}" method="xml" indent="no">
				<xsl:sequence select="$content"/>
			</xsl:result-document>
		</xsl:if>
	</xsl:template>
	
</xsl:stylesheet>
