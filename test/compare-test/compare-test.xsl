<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema"
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">
	
	<xsl:param name="outputFolder" as="xs:string" select="concat(base-uri(.), '-OUTPUT/')"/>
	
	<xsl:include href="../../xsl/compare.xsl"/>
	<xsl:include href="../../xsl/normalize/normalize-core.xsl"/>
	
	
	<xsl:template match="/" priority="100">
		
		<xsl:variable name="result" as="document-node()">
			<xsl:call-template name="compareTest">
				<xsl:with-param name="doc"			select="."/>
				<xsl:with-param name="debugOutput"	select="true()"/>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:result-document href="{$outputFolder}currNormalized.xml" method="xml" indent="no">
			<xsl:text>&#x0A;</xsl:text>
			<xsl:apply-templates select="$result/CurrNormalized" mode="indent"/>
		</xsl:result-document>
		<xsl:result-document href="{$outputFolder}prevNormalized.xml" method="xml" indent="no">
			<xsl:text>&#x0A;</xsl:text>
			<xsl:apply-templates select="$result/PrevNormalized" mode="indent"/>
		</xsl:result-document>
		
		<xsl:if test="$result/CurrNormalized2">
			<xsl:result-document href="{$outputFolder}currNormalized2.xml" method="xml" indent="no">
				<xsl:text>&#x0A;</xsl:text>
				<xsl:apply-templates select="$result/CurrNormalized2" mode="indent"/>
			</xsl:result-document>
			<xsl:result-document href="{$outputFolder}prevNormalized2.xml" method="xml" indent="no">
				<xsl:text>&#x0A;</xsl:text>
				<xsl:apply-templates select="$result/PrevNormalized2" mode="indent"/>
			</xsl:result-document>
		</xsl:if>
		
		<xsl:result-document href="{$outputFolder}lcsDebuggingInfo.xml" method="xml" indent="no">
			<xsl:text>&#x0A;</xsl:text>
			<xsl:apply-templates select="$result/LcsDebuggingInfo" mode="indent"/>
		</xsl:result-document>

		<xsl:text>&#x0A;</xsl:text>
		<xsl:apply-templates select="$result/result" mode="write">
			<xsl:with-param name="outputUri" 	select="base-uri(.)"/>
			<xsl:with-param name="rootResult" 	select="$result" 	tunnel="yes"/>
			<xsl:with-param name="writeDocs"	select="false()"	tunnel="yes"/>
		</xsl:apply-templates>
			
	</xsl:template>
	
	
	<xsl:template name="compareTest" as="document-node()">
		<xsl:param name="doc"			as="document-node()"/>
		<xsl:param name="debugOutput"	as="xs:boolean"		select="false()"/>
		
		<xsl:variable name="protectTextMatchSize"	as="xs:integer"	select="if ($doc/*/@protectTextMatchSize) 	then $doc/*/@protectTextMatchSize 	else $protectTextMatchSize"/>
		<xsl:variable name="protectTextMatchRatio"	as="xs:double"	select="if ($doc/*/@protectTextMatchRatio) 	then $doc/*/@protectTextMatchRatio 	else $protectTextMatchRatio"/>
		<xsl:variable name="doSingleWordCompare"	as="xs:boolean"	select="if ($doc/*/@doSingleWordCompare) 	then $doc/*/@doSingleWordCompare 	else $doSingleWordCompare"/>
		
		<xsl:variable name="currNormalized" as="element()">
			<xsl:apply-templates select="$doc/root/curr/*[1]" mode="normalize">
				<xsl:with-param name="setBaseUri"	select="true()"/>
			</xsl:apply-templates>
			<!--<xsl:sequence select="$doc/root/curr/*[1]"/>-->
		</xsl:variable>
		<xsl:variable name="prevNormalized" as="element()">
			<xsl:apply-templates select="$doc/root/prev/*[1]" mode="normalize">
				<xsl:with-param name="setBaseUri"	select="true()"/>
			</xsl:apply-templates>
			<!--<xsl:sequence select="$doc/root/prev/*[1]"/>-->
		</xsl:variable>
		
		<xsl:document>
		
			<xsl:if test="$debugOutput">
				<xsl:variable name="isTextMode" as="xs:boolean" select="($currNormalized/@dsd:text) or ($prevNormalized/@dsd:text)"/>
				
				<CurrNormalized>
					<xsl:sequence select="$currNormalized"/>
				</CurrNormalized>
				<PrevNormalized>
					<xsl:sequence select="$prevNormalized"/>
				</PrevNormalized>
				
				<xsl:variable name="currNormalized2" as="element()">
					<xsl:choose>
						<xsl:when test="$isTextMode">
							<dsd:textParent>
								<xsl:attribute name="xml:base" select="base-uri($doc)"/>
								<xsl:apply-templates select="$currNormalized/node()" mode="splitText"/>
							</dsd:textParent>
						</xsl:when>
						<xsl:otherwise>
							<xsl:sequence select="$currNormalized"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="prevNormalized2" as="element()">
					<xsl:choose>
						<xsl:when test="$isTextMode">
							<dsd:textParent>
								<xsl:attribute name="xml:base" select="base-uri($doc)"/>
								<xsl:apply-templates select="$prevNormalized/node()" mode="splitText"/>
							</dsd:textParent>
						</xsl:when>
						<xsl:otherwise>
							<xsl:sequence select="$prevNormalized"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<xsl:if test="$isTextMode">
					<CurrNormalized2>
						<xsl:sequence select="$currNormalized2"/>
					</CurrNormalized2>
					<PrevNormalized2>
						<xsl:sequence select="$prevNormalized2"/>
					</PrevNormalized2>
				</xsl:if>
				
				<LcsDebuggingInfo>
					<xsl:namespace name="dsd">http://www.dita-semia.org/diff</xsl:namespace>
					<xsl:if test="($currNormalized2/element()) and ($prevNormalized2/element())">
						<xsl:call-template name="lcs">
							<xsl:with-param name="parent1"					select="$currNormalized2"/>
							<xsl:with-param name="parent2"					select="$prevNormalized2"/>
							<xsl:with-param name="debugOutput"				select="true()"/>
							<xsl:with-param name="isTextMode"				select="$isTextMode"			tunnel="yes"/>
							<xsl:with-param name="protectTextMatchSize"		select="$protectTextMatchSize" 	tunnel="yes"/>
							<xsl:with-param name="protectTextMatchRatio"	select="$protectTextMatchRatio" tunnel="yes"/>
							<xsl:with-param name="doSingleWordCompare"		select="$doSingleWordCompare" 	tunnel="yes"/>
						</xsl:call-template>
					</xsl:if>
				</LcsDebuggingInfo>
			</xsl:if>
			
			<result>
				<xsl:apply-templates select="$currNormalized" mode="processMatch">
					<xsl:with-param name="matchNode" 				select="$prevNormalized"/>
					<xsl:with-param name="protectTextMatchSize"		select="$protectTextMatchSize" 	tunnel="yes"/>
					<xsl:with-param name="protectTextMatchRatio"	select="$protectTextMatchRatio" tunnel="yes"/>
					<xsl:with-param name="doSingleWordCompare"		select="$doSingleWordCompare" 	tunnel="yes"/>
				</xsl:apply-templates>
			</result>
		</xsl:document>
	</xsl:template>
	
	
	<xsl:template match="result/*/@xml:base" mode="write writeSpacePreserve">
		<!-- drop it -->
	</xsl:template>
		
	<xsl:template match="@xml:base" mode="write writeSpacePreserve">
		<xsl:param name="outputUri" as="xs:anyURI"/>
		<!-- make comparing of results independent from base directory -->
		<xsl:attribute name="xml:base" select="dsd:relativizeHref(., $outputUri)"/>
	</xsl:template>
	
	
	<xsl:mode name="indent" on-no-match="shallow-copy"/>


	<xsl:template match="element()[(@xml:space = 'preserve') or (@dsd:text = true())]" mode="indent">
		<xsl:copy-of select="." copy-namespaces="false"/>
	</xsl:template>
	
	
	<xsl:template match="element()" mode="indent">
		<xsl:param name="indent" 		as="xs:string?"/>
		<xsl:param name="singleIndent" 	as="xs:string"	select="'&#x09;'" tunnel="yes"/>
		
		<xsl:copy copy-namespaces="false">
			<xsl:apply-templates select="attribute()" mode="#current"/>
			
			<!-- don't do indentation when there is already text content --> 
			<xsl:variable name="doIndent" as="xs:boolean" select="empty(text())"/>
			
			<xsl:for-each select="node()"> 
				<xsl:if test="$doIndent">
					<xsl:value-of select="concat('&#xA;', $indent, $singleIndent)"/>
				</xsl:if>
				<xsl:apply-templates select="." mode="#current">
					<xsl:with-param name="indent" 		select="concat($indent, $singleIndent)"/>
				</xsl:apply-templates>
			</xsl:for-each>
			<xsl:if test="(node()) and ($doIndent)">
				<xsl:value-of select="concat('&#xA;', $indent)"/>
			</xsl:if>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>