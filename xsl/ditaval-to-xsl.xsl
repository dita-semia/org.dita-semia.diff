<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema" 
	xmlns:axsl	= "http://www.w3.org/1999/XSL/TransformAlias" 
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">
	
	<xsl:output method="text"/>
	
	<xsl:param name="xslFile" 	as="xs:string" 	select="resolve-uri('filter-prev.xsl')"/>
	
	<xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>
	
	<xsl:variable name="QUOT" as="xs:string">'</xsl:variable>
	
	
	<xsl:template match="/">
		
		<xsl:variable name="filterTemplates" as="element()*">
			<xsl:for-each-group select="val/(prop | revprop)[@action = 'exclude']" group-by="dsd:getAtt(.)">
				<xsl:variable name="excludeVals" as="xs:string*" select="distinct-values(current-group()/@val)"/>
				<axsl:variable name="exclude-{current-grouping-key()}-vals" 	as="xs:string*" select="('{string-join($excludeVals, concat($QUOT, ', ', $QUOT))}')"/>
				<axsl:template match="*[@{current-grouping-key()}]" mode="normalize" priority="{1000 - position()}">
					<axsl:variable name="origVal" as="xs:string">
						<axsl:variable name="thisVal" 	as="xs:string" select="string(@{current-grouping-key()})"/>
						<axsl:variable name="parentVal" as="xs:string" select="concat(' ', parent::*/@{current-grouping-key()})"/>
						<axsl:choose>
							<axsl:when test="contains(@class, ' map/topicref ') and ends-with($thisVal, $parentVal)">
								<axsl:sequence select="substring($thisVal, 1, string-length($thisVal) - string-length($parentVal))"/>
							</axsl:when>
							<axsl:otherwise>
								<axsl:sequence select="$thisVal"></axsl:sequence>
							</axsl:otherwise>
						</axsl:choose>
					</axsl:variable>
					<axsl:variable name="vals" 			as="xs:string*" select="tokenize($origVal, '\s+')"/>
					<!--<axsl:message>filter <axsl:value-of select="name(.)"/>: {current-grouping-key()} = [<axsl:value-of select="string-join($vals, ', ')"/>]</axsl:message>-->
					<axsl:if test="exists($vals[not(. = $exclude-{current-grouping-key()}-vals)])">
						<axsl:next-match/>
					</axsl:if>
				</axsl:template>
			</xsl:for-each-group>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="exists($filterTemplates)">
				<xsl:result-document href="file:/{replace($xslFile, '\\', '/')}" method="xml" indent="yes">
					
					<axsl:stylesheet version="3.0" exclude-result-prefixes="#all" expand-text="true">
						<xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
						
						<axsl:import href="plugin:org.dita-semia.diff:xsl/normalize.xsl"/>
						
						<xsl:sequence select="$filterTemplates"/>
					</axsl:stylesheet>
				</xsl:result-document>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>Ditaval file contains no excludes, thus, no filtering required.</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
		
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
