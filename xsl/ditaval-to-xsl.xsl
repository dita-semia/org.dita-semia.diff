<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema" 
	xmlns:axsl	= "http://www.w3.org/1999/XSL/TransformAlias" 
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">
	
	<xsl:param name="xslFile" 	as="xs:string" 	select="resolve-uri('filter-prev.xsl')"/>
	
	<xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>
	
	<xsl:variable name="QUOT" as="xs:string">'</xsl:variable>
	
	
	<xsl:template match="/">
		
		<xsl:variable name="filterTemplates" as="element()*">
			<xsl:for-each-group select="val/(prop | revprop)[@action = 'exclude']" group-by="dsd:getAtt(.)">
				<xsl:variable name="excludeVals" as="xs:string*" select="distinct-values(current-group()/@val)"/>
				<axsl:template match="*[@{current-grouping-key()}]" mode="normalize" priority="{1000 - position()}">
					<axsl:variable name="vals" 			as="xs:string*" select="tokenize(@{current-grouping-key()}, '\s+')"/>
					<axsl:variable name="excludeVals" 	as="xs:string*" select="('{string-join($excludeVals, concat($QUOT, ', ', $QUOT))}')"/>
					<axsl:if test="exists($vals[not(. = $excludeVals)])">
						<axsl:next-match/>
					</axsl:if>
				</axsl:template>
			</xsl:for-each-group>
		</xsl:variable>
		
		<xsl:if test="exists($filterTemplates)">
			<xsl:result-document href="file:/{replace($xslFile, '\\', '/')}" method="xml" indent="yes">
				
				<axsl:stylesheet version="3.0" exclude-result-prefixes="#all" expand-text="true">
					<xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
					
					<axsl:import href="plugin:org.dita-semia.diff:xsl/normalize.xsl"/>
					
					<xsl:sequence select="$filterTemplates"/>
				</axsl:stylesheet>
			</xsl:result-document>	
		</xsl:if>
	</xsl:template>
	

	<xsl:function name="dsd:getAtt" as="xs:string">
		<xsl:param name="prop" as="element()"/>
		
		<xsl:choose>
			<xsl:when test="$prop/self::revprop">
				<xsl:sequence select="'rev'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$prop/@att"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

</xsl:stylesheet>
