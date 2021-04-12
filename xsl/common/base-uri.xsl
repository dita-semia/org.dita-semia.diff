<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema" 
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">
	
	
	<!--
		The standard function base-uri works unreliable in combination with @xml:base und directory structures. Thus, it has been reimplemented manually.
	-->

	<xsl:function name="dsd:base-uri" as="xs:anyURI?">
		<xsl:param name="item" as="item()?"/>
		
		<xsl:if test="exists($item)">
			<xsl:apply-templates select="$item" mode="base-uri"/>
		</xsl:if>
	</xsl:function>
	
	<xsl:mode name="base-uri" on-no-match="fail"/>
	
	<xsl:template match="*[@xml:base]" as="xs:anyURI?" mode="base-uri" priority="3">
		<xsl:sequence select="xs:anyURI(@xml:base)"/>
	</xsl:template>
	
	<xsl:template match="(node() | attribute())[parent::*]" as="xs:anyURI?" mode="base-uri" priority="2">
		<xsl:apply-templates select="parent::*" mode="#current"/>
	</xsl:template>
	
	<xsl:template match="document-node() | element() | attribute()" as="xs:anyURI?" mode="base-uri" priority="1">
		<xsl:sequence select="base-uri()"/>
	</xsl:template>

</xsl:stylesheet>
