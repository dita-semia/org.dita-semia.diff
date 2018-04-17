<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema" 
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="yes">
	
	
	
	<xsl:mode name="getHash" on-no-match="shallow-skip"/>

	<xsl:template match="element()" mode="getHash" as="xs:integer?">
		<xsl:sequence select="@dsd:hash"/>
	</xsl:template>

	<xsl:template match="text()" mode="getHash" as="xs:integer?">
		<xsl:sequence select="dsd:getHashFromString(.)"/>
	</xsl:template>
	
	<xsl:template match="*[contains(@class, $CLASS_IMAGE)]/@href" mode="getHash" as="xs:integer?">
		<!-- Ignore the href for comparing. Use the hash o the referenced file instead coming from @dsd:refHashCode -->
	</xsl:template>
	
	<xsl:template match="@xtrf | @xtrc | @dsd:size | @dsd:hash | @dsd:text" mode="getHash" as="xs:integer?">
		<!-- ignore for diff -->
	</xsl:template>

	<xsl:template match="attribute()" mode="getHash" as="xs:integer?">
		<xsl:sequence select="dsd:getHashFromString(concat(name(), '=', .))"/>
	</xsl:template>
	
	
	
	
	<xsl:mode name="getSize" on-no-match="shallow-skip"/>
	
	<xsl:template match="*[contains(@class, $CLASS_TOPICMETA) or contains(@class, $CLASS_METADATA)]" mode="getSize" as="xs:integer?">
		<!-- metadata content doesn't add to the size of the containing element -->
	</xsl:template>
	
	<xsl:template match="element()" mode="getSize" as="xs:integer?">
		<xsl:sequence select="@dsd:size"/>
	</xsl:template>
	
	<xsl:template match="text()" mode="getSize" as="xs:integer?">
		<xsl:sequence select="string-length(.)"/>
	</xsl:template>
	
	<xsl:template match="attribute()" mode="getSize" as="xs:integer?">
		<!-- attributes don't contribute to the size -->
	</xsl:template>
	
	<xsl:template match="*[contains(@class, $CLASS_IMAGE)]/@href" mode="getSize" as="xs:integer?">
		<xsl:sequence select="10"/>	<!-- just some value -->
	</xsl:template>
	

</xsl:stylesheet>
