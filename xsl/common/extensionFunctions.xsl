<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema" 
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="yes">
	
	
	
	<xsl:function name="dsd:getHashFromString" as="xs:integer" use-when="not(function-available('dsd:getHashFromString'))">
		<xsl:param name="string" as="xs:string"/>
		<xsl:sequence select="0"/>
	</xsl:function>
	
	<xsl:function name="dsd:getHashFromSequence" as="xs:integer" use-when="not(function-available('dsd:getHashFromSequence'))">
		<xsl:param name="ints" as="item()*"/>
		<xsl:sequence select="0"/>
	</xsl:function>
	
	<xsl:function name="dsd:getHashFromFile" as="xs:integer" use-when="not(function-available('dsd:getHashFromFile'))">
		<xsl:param name="url" 			as="xs:anyURI"/>
		<xsl:param name="normalizeNl" 	as="xs:boolean"/>
		<xsl:sequence select="0"/>
	</xsl:function>
	
	<xsl:function name="dsd:relativizeHref" as="xs:string" use-when="not(function-available('dsd:relativizeHref'))">
		<xsl:param name="href" 		as="xs:string"/>
		<xsl:param name="baseUri" 	as="xs:anyURI"/>
		<xsl:sequence select="$href"/>
	</xsl:function>
	
	<xsl:function name="dsd:serialize" as="xs:string" use-when="not(function-available('dsd:serialize'))">
		<xsl:param name="node" as="node()"/>
		<xsl:sequence select="''"/>
	</xsl:function>
	
</xsl:stylesheet>
