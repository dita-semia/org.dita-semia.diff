<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema" 
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">
	
	
	
	<xsl:mode name="normalize" on-no-match="shallow-copy"/>
	
	<xsl:key name="xtrc" match="*[@xtrc]" use="@xtrc"/>
		
	<xsl:template match="element()" mode="normalize">
		<xsl:param name="refHash"		as="xs:integer?"/>
		<xsl:param name="refSize"		as="xs:integer?"/>
		<xsl:param name="conrefParent"	as="element()?"/>
		<xsl:param name="spacePreserve"	as="xs:boolean" select="false()"/>
		<xsl:param name="spaceCollapse"	as="xs:boolean" select="false()"/>
		<xsl:param name="setBaseUri"	as="xs:boolean" select="false()"/>
		
		<xsl:variable name="conrefElement" as="element()?">
			<xsl:choose>
				<xsl:when test="exists(@dsd:id)">
					<!-- no need to check, has already been set -->
				</xsl:when>
				<xsl:when test="exists($conrefParent)">
					<!-- get the child from the conref parent on the same position -->
					<xsl:sequence select="$conrefParent/*[count(current()/preceding-sibling::*) + 1]"/>
				</xsl:when>
				<xsl:when test="exists(@xtrc) and (@xtrf ne parent::*/@xtrf) and not(contains(@class, ' map/topicref ') or contains(@class, ' topic/link '))">
					<xsl:variable name="relUri" as="xs:string" select="dsd:relativizeHref(@xtrf, parent::*/@xtrf)"/>
					<xsl:variable name="absUri" as="xs:anyURI" select="resolve-uri($relUri, base-uri(.))"/>
					<!--<xsl:message>XXXXXXXXXXXXXXXXXX {$absUri}</xsl:message>-->
					<!--<xsl:message>XXXXXXXXXXXXXX conref - {@class}, {@xtrc}, {$absUri}</xsl:message>-->
					<!-- conref started -->
					<xsl:if test="doc-available($absUri)">
						<xsl:variable name="conrefDoc" as="document-node()?" select="doc($absUri)"/>
						<xsl:sequence select="key('xtrc', @xtrc, $conrefDoc)"/>
					</xsl:if>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="dsdId" as="attribute()?">
			<xsl:if test="exists(@id) and exists($conrefElement/@id)">
				<!--<xsl:message>************** id: {$conrefElement/@id}</xsl:message>-->
				<xsl:attribute name="dsd:id" select="$conrefElement/@id"/>
			</xsl:if>
		</xsl:variable>

		<xsl:copy>
			<xsl:if test="(parent::document-node()) or ($setBaseUri)">
				<xsl:if test="parent::document-node()">
					<xsl:message>Normalizing file {base-uri()}</xsl:message>
				</xsl:if>
				<xsl:attribute name="xml:base" select="base-uri()"/>	
			</xsl:if>
			
			<xsl:variable name="contentWrapper" as="element()">
				<xsl:copy> <!-- maintain context -->
					<xsl:choose>
						
						<xsl:when test="($spacePreserve) or (@xml:space = 'preserve') or (@dsd:text)">
							<xsl:call-template name="normalizeAttributes">
								<xsl:with-param name="dsdAttributes" as="attribute()*">
									<xsl:attribute name="dsd:text" select="true()"/>
									<xsl:sequence select="$dsdId"/>
								</xsl:with-param>
							</xsl:call-template>
							<xsl:apply-templates select="node()" mode="#current">
								<xsl:with-param name="conrefParent"		select="$conrefElement"/>
								<xsl:with-param name="spacePreserve" 	select="true()"/>
							</xsl:apply-templates>
						</xsl:when>
						
						<xsl:when test="exists(text()[matches(., '[^\s]')])">
							<xsl:call-template name="normalizeAttributes">
								<xsl:with-param name="dsdAttributes" as="attribute()*">
									<xsl:if test="not($spaceCollapse)">
										<!-- mark element as containing text -->
										<xsl:attribute name="dsd:text" select="true()"/>
										<xsl:sequence select="$dsdId"/>
									</xsl:if>
								</xsl:with-param>
							</xsl:call-template>
							<xsl:apply-templates select="node()" mode="#current">
								<xsl:with-param name="conrefParent"		select="$conrefElement"/>
								<xsl:with-param name="spaceCollapse" 	select="true()"/>
							</xsl:apply-templates>
						</xsl:when>
						
						<xsl:otherwise>
							<xsl:variable name="normalizedRef" as="document-node()?">
								<xsl:if test="(contains(@class, $CLASS_TOPICREF)) and (string(@href) != '')">
									<xsl:variable name="refUri" as="xs:anyURI" 			select="resolve-uri(@href, base-uri(.))"/>
									<xsl:choose>
										<xsl:when test="doc-available($refUri)">
											<xsl:apply-templates select="doc($refUri)" mode="normalize"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:message>WARNUNG: referenced file could not be loaded: {$refUri}</xsl:message>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:if>
							</xsl:variable>
							<xsl:call-template name="normalizeAttributes">
								<xsl:with-param name="dsdAttributes" as="attribute()*">
									<xsl:variable name="refId" as="xs:string?" select="$normalizedRef/*/@id"/>
									<xsl:if test="not(string($refId) = '')">
										<xsl:attribute name="dsd:refId" select="$refId"/>
									</xsl:if>
									<xsl:sequence select="$dsdId"/>
								</xsl:with-param>
							</xsl:call-template>
							<xsl:sequence select="$normalizedRef"/>
							<xsl:apply-templates select="node()" mode="#current">
								<xsl:with-param name="conrefParent"		select="$conrefElement"/>
								<xsl:with-param name="spaceCollapse"	select="$spaceCollapse"/>
							</xsl:apply-templates>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:copy>
			</xsl:variable>
			
			<xsl:variable name="hashList" as="xs:integer*">
				<xsl:sequence select="dsd:getHashFromString(name($contentWrapper))"/>
				<xsl:apply-templates select="$contentWrapper/(attribute() | node())" mode="getHash"/>
			</xsl:variable>
			
			<xsl:variable name="sizeList" as="xs:integer*">
				<xsl:apply-templates select="$contentWrapper/(attribute() | node())" mode="getSize"/>
			</xsl:variable>
			
			<xsl:attribute name="dsd:hash" select="dsd:getHashFromSequence(($hashList, $refHash))"/>
			<xsl:attribute name="dsd:size" select="max((sum(($sizeList, $refSize)), 1))"/>
			
			
			<xsl:sequence select="$contentWrapper/(attribute() | node())"/>
		</xsl:copy>
	</xsl:template>
	
	
	<xsl:template match="*[contains(@class, $CLASS_IMAGE)]/@href" mode="normalize">
		<xsl:copy/> 

		<!-- add another attribute for the hash of the referenced file -->
		<xsl:variable name="refUri" as="xs:anyURI" select="if (parent::*/@xtrf) then resolve-uri(., parent::*/@xtrf) else resolve-uri(., base-uri())"/>
		<xsl:attribute name="dsd:refHashCode" select="dsd:getHashFromFile($refUri)"/>
	</xsl:template>
	
	
	<xsl:template match="text()" mode="normalize">
		<xsl:param name="spacePreserve"	as="xs:boolean" select="false()"/>
		<xsl:param name="spaceCollapse"	as="xs:boolean" select="false()"/>
		
		<xsl:choose>
			<xsl:when test="$spacePreserve">
				<xsl:copy/>
			</xsl:when>
			<xsl:when test="($spaceCollapse) and matches(., '^\s+$') and empty(following-sibling::node())">
				<!-- drop whitespaces at the end -->
			</xsl:when>
			<xsl:when test="$spaceCollapse">
				<xsl:value-of select="replace(., '\s+', ' ')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<xsl:template match="@xtrf | @xtrc | comment()" mode="normalize">
		<xsl:param name="filterNoise" as="xs:boolean" select="false()" tunnel="yes"/>
		
		<xsl:if test="not($filterNoise)">
			<xsl:next-match/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="@dsd:size | @dsd:hash" mode="normalize">
		<!-- don't copy when already existing - should be generated newly after filtering -->
	</xsl:template>
	
	<xsl:template name="normalizeAttributes">
		<xsl:param name="dsdAttributes" as="attribute()*"/>
		
		<xsl:for-each select="attribute() | $dsdAttributes">
			<xsl:sort select="name()"/>
			<xsl:apply-templates select="." mode="normalize"/>	
		</xsl:for-each>
	</xsl:template>
	
	

</xsl:stylesheet>
