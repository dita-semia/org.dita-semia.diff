<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema"
	exclude-result-prefixes="#all"
	version="2.0">
	
	<xsl:output method="text"/>
	
	<xsl:template match="/">
		<xsl:variable name="filename" 		as="xs:string" 	select="tokenize(base-uri(), '[/\\]')[last()]"/>
		<xsl:variable name="filenameBase" 	as="xs:string" 	select="replace($filename, '[.][^.]+$', '')"/>
		<xsl:variable name="version" 		as="xs:string?" select="normalize-space(/*/bookmeta/data[@name = 'VersionNumber'])"/>

		<xsl:sequence select="concat($filenameBase, '-v', $version, '.zip')"/>
	</xsl:template>
	
</xsl:stylesheet>