<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema" 
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">
	
	
	<xsl:param name="tmpUriSuffix" 		as="xs:string" 	select="'.tmp'"/>
	<xsl:param name="filterNoise" 		as="xs:string" 	select="'false'"/>
	<xsl:param name="singleIndent" 		as="xs:string" 	select="'&#x09;'"/>


	<xsl:include href="common/consts.xsl"/>
	<xsl:include href="common/getHashSize.xsl"/>
	<xsl:include href="common/extensionFunctions.xsl"/>
	<xsl:include href="normalize/normalize-core.xsl"/>
	<xsl:include href="normalize/write.xsl"/>
	
	<xsl:template match="/">
		<xsl:variable name="normalized">
			<xsl:apply-templates select="node()" mode="normalize">
				<xsl:with-param name="filterNoise" select="$filterNoise = ('1', 'yes', 'true')" tunnel="yes"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:apply-templates select="$normalized" mode="write"/>
	</xsl:template>


</xsl:stylesheet>
