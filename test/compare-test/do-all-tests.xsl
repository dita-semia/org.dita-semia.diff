<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema"
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">
	
	
	<xsl:include href="compare-test.xsl"/>
	
	<xsl:output method="text"/>
	
	
	<xsl:template match="/" priority="200">

		<xsl:for-each select="list/test">
			<xsl:message select="text()"/>
			<xsl:text>{.}:</xsl:text>
			<xsl:variable name="doc" as="document-node()" select="doc(resolve-uri(.))"/>
			
			<xsl:variable name="result" as="document-node()">
				<xsl:call-template name="compareTest">
					<xsl:with-param name="doc"	select="$doc"/>
				</xsl:call-template>
			</xsl:variable>

			<xsl:variable name="indentResult" as="element()">
				<xsl:apply-templates select="$result/result" mode="write">
					<xsl:with-param name="outputUri" 	select="base-uri($doc)"/>
					<xsl:with-param name="indent" 		select="$singleIndent"/>	<!-- start with some indention to match with the input document -->
					<xsl:with-param name="rootResult" 	select="$result" 	tunnel="yes"/>
					<xsl:with-param name="writeDocs"	select="false()"	tunnel="yes"/>
				</xsl:apply-templates>
			</xsl:variable>
			
			
			<xsl:variable name="indentResultString" as="xs:string" select="dsd:serialize($indentResult)"/>
			<xsl:variable name="expectedString" 	as="xs:string" select="dsd:serialize($doc/root/result)"/>
			
			<xsl:choose>
				<xsl:when test="$indentResultString = $expectedString">
					<xsl:text> OK</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text> FAIL&#x0A;</xsl:text>
					<xsl:text> result: &#x0A;</xsl:text>
					<xsl:value-of select="concat($singleIndent, $indentResultString)"/>
					<xsl:text>&#x0A; expected:&#x0A;</xsl:text>
					<xsl:value-of select="concat($singleIndent, $expectedString)"/>
					<xsl:text>&#x0A;</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text>&#x0A;</xsl:text>
		</xsl:for-each>

	</xsl:template>
	
</xsl:stylesheet>
