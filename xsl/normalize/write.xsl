<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema"
	xmlns:svg	= "http://www.w3.org/2000/svg"
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all">
	
	
	<xsl:mode name="write" on-no-match="shallow-copy"/>
	
	
	<xsl:template match="element()[(@xml:space = 'preserve') or (@dsd:text = true())]" mode="write">
		<xsl:copy-of select="."/>	<!-- deep copy -->
	</xsl:template>
	
	
	<xsl:template match="element()" mode="write">
		<!--<xsl:param name="indent" as="xs:string?"/>-->
		<xsl:copy>
			<xsl:apply-templates select="attribute()" mode="#current"/>
			
			<xsl:for-each select="node()[empty(@xml:base)]"> 
				<!--<xsl:value-of select="concat('&#xA;', $indent, $singleIndent)"/>-->
				<xsl:apply-templates select="." mode="#current">
					<!--<xsl:with-param name="indent" select="concat($indent, $singleIndent)"/>-->
				</xsl:apply-templates>
			</xsl:for-each>
			<!--<xsl:if test="node()">
				<xsl:value-of select="concat('&#xA;', $indent)"/>
			</xsl:if>-->
		</xsl:copy>
		
		<xsl:for-each select="*[@xml:base]">
			<xsl:result-document href="{@xml:base}{$tmpUriSuffix}" method="xml" indent="no">
				<xsl:text>&#x0A;</xsl:text>
				<xsl:apply-templates select="." mode="#current"/>
			</xsl:result-document>
		</xsl:for-each>
	</xsl:template>
	
	
	<xsl:template match="document-node()" mode="write">
		<xsl:for-each select="node()">
			<xsl:value-of select="if (position() > 0) then '&#xA;' else ''"/>
			<xsl:apply-templates select="." mode="#current"/>
		</xsl:for-each>
	</xsl:template>
	
	
	<xsl:template match="@xml:base" mode="write">
		<!-- drop this attribute -->
	</xsl:template>
	
	<xsl:template match="svg:*/@dsd:*" mode="write">
		<!-- drop dsd-attribute on svg elements-->
	</xsl:template>
	

	
</xsl:stylesheet>
