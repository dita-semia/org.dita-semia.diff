<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema" 
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">


	<xsl:variable name="CLASS_TOPICREF"			as="xs:string"	select="' map/topicref '"/>
	<xsl:variable name="CLASS_TOPICMETA"		as="xs:string"	select="' map/topicmeta '"/>
	<xsl:variable name="CLASS_METADATA"			as="xs:string"	select="' topic/metadata '"/>
	<xsl:variable name="CLASS_IMAGE"			as="xs:string"	select="' topic/image '"/>
	<xsl:variable name="CLASS_XREF"				as="xs:string"	select="' topic/xref '"/>
	<xsl:variable name="CLASS_KEYWORD"			as="xs:string"	select="' topic/keyword '"/>
	<xsl:variable name="CLASS_SVG_CONTAINER"	as="xs:string"	select="' svg-d/svg-container '"/>
	<xsl:variable name="CLASS_DATA"				as="xs:string"	select="' topic/data '"/>
	
	<xsl:variable name="CLASS_PATH_KEY_XREF"	as="xs:string"	select="'+ topic/ph akr-d/key-xref '"/>


	<xsl:variable name="CHANGE_ADDED"			as="xs:string"	select="'added'"/>
	<xsl:variable name="CHANGE_DELETED"			as="xs:string"	select="'deleted'"/>
	
	<!--<xsl:variable name="WRAPPER_TEXT"			as="xs:string"	select="'text'"/>-->

	<xsl:variable name="DITAOT_PI_GENTEXT"		as="xs:string"	select="'gentext'"/>
	<xsl:variable name="DITAOT_PI_USERTEXT"		as="xs:string"	select="'usertext'"/>

</xsl:stylesheet>
