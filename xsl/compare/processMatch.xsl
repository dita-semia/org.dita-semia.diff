<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema" 
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">
	
	
	<xsl:mode name="processMatch" on-no-match="fail" on-multiple-match="fail"/>
	
	
	<xsl:template match="element()" mode="processMatch" priority="100">
		<xsl:param name="matchNode" as="node()"/>
		
		<xsl:choose>
			<xsl:when test="./@dsd:hash = $matchNode/@dsd:hash">
				<xsl:apply-templates select="." mode="unchanged"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:next-match>
					<xsl:with-param name="matchNode" select="$matchNode"/>
				</xsl:next-match>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="document-node() | element()" mode="processMatch">
		<xsl:param name="matchNode" as="node()"/>
		
		<xsl:copy>
			<xsl:apply-templates select="attribute()" mode="processMatch">
				<xsl:with-param name="matchNode" select="$matchNode"/>
			</xsl:apply-templates>
			<!-- ignore attributes of 2nd compareNode -->
			
			<!-- add base-uri to be able to resolve embedded URIs in result -->
			<xsl:if test="parent::document-node()">
				<xsl:attribute name="xml:base" select="base-uri(.)"/>
			</xsl:if>
			
			<!--<xsl:if test="contains(@class, $CLASS_TOPICREF)">
				<xsl:message>processMatch topicref {@href|@navtitle}, {$matchNode/@href|$matchNode/@navtitle}</xsl:message>
			</xsl:if>-->
			
			<xsl:apply-templates select="." mode="compareContent">
				<xsl:with-param name="parent2" select="$matchNode"/>
			</xsl:apply-templates>
			<!--<xsl:call-template name="compareContent">
				<xsl:with-param name="parent1" select="."/>
				<xsl:with-param name="parent2" select="$matchNode"/>
			</xsl:call-template>-->
		</xsl:copy>
	</xsl:template>


	<xsl:template match="attribute()" mode="processMatch">
		<xsl:copy/>
	</xsl:template>


	<xsl:template match="*[contains(@class, $CLASS_TOPICREF)]/@href" mode="processMatch">
		<xsl:param name="matchNode" as="node()"/>
		
		<xsl:next-match/>
		<!-- 
			Add the URI of the node this file should be compared to during write mode.
			Since the main template is within the context of a variable xsl:result-document can't be used now.
		-->
		<xsl:attribute name="dsd:matchHref" select="resolve-uri($matchNode/@href, base-uri($matchNode))"/>
	</xsl:template>


</xsl:stylesheet>
