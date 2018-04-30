<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema" 
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">
	
	
	<xsl:mode name="added" 			on-no-match="shallow-copy"/>
	<xsl:mode name="addedContent" 	on-no-match="shallow-copy"/>
	
	
	
	<xsl:template match="*" mode="added">
		<xsl:param name="isTextMode" 	as="xs:boolean?"	select="false()" tunnel="yes"/>

		<xsl:copy>
			<xsl:apply-templates select="attribute()" mode="addedContent"/>
			<xsl:attribute name="dsd:change" select="$CHANGE_ADDED"/>
			<xsl:choose>
				<xsl:when test="not($isTextMode) or (empty(@dsd:mergeCode))">
					<xsl:call-template name="changedContent">
						<xsl:with-param name="isAdded" select="true()"/>
						<xsl:with-param name="content" as="node()*">
							<xsl:apply-templates select="node()" mode="deletedContent"/>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="node()" mode="addedContent"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
		
	<xsl:template match="dsd:text | *[@dsd:atomic]" mode="added addedContent">
		<xsl:copy>
			<xsl:apply-templates select="attribute()" mode="addedContent"/>
			<xsl:attribute name="dsd:change" select="$CHANGE_ADDED"/>
			<xsl:apply-templates select="node()" mode="addedContent"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="text()" mode="added">
		<xsl:message terminate="yes">ERROR: can't mark plain text as being added. ({.})</xsl:message>
	</xsl:template>
	


	<xsl:mode name="deleted" 			on-no-match="shallow-copy"/>
	<xsl:mode name="deletedContent" 	on-no-match="shallow-copy"/>

	<xsl:template match="*" mode="deleted">
		<xsl:param name="isTextMode" 	as="xs:boolean?"	select="false()" tunnel="yes"/>

		<xsl:copy>
			<xsl:apply-templates select="attribute()" mode="deletedContent"/>
			<xsl:attribute name="dsd:change" select="$CHANGE_DELETED"/>
			<xsl:choose>
				<xsl:when test="not($isTextMode) or (empty(@dsd:mergeCode))">
					<xsl:call-template name="changedContent">
						<xsl:with-param name="isAdded" select="false()"/>
						<xsl:with-param name="content" as="node()*">
							<xsl:apply-templates select="node()" mode="deletedContent"/>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="node()" mode="deletedContent"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	
	
	<xsl:template match="text()" mode="deleted">
		<xsl:message terminate="yes">ERROR: can't mark plain text as being deleted. ({.})</xsl:message>
	</xsl:template>
	
	<xsl:template match="dsd:text | *[@dsd:atomic]" mode="deleted deletedContent">
		<xsl:copy>
			<xsl:apply-templates select="attribute()" mode="deletedContent"/>
			<xsl:attribute name="dsd:change" select="$CHANGE_DELETED"/>
			<xsl:apply-templates select="node()" mode="deletedContent"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="processing-instruction('ditaot')" mode="deleted deletedContent">
		<xsl:copy/>	<!-- is required at some place, e.g. within xref to identify content as usertext-->
	</xsl:template>
	
	<xsl:template match="processing-instruction() | comment()" mode="deleted deletedContent">
		<!-- don't copy -->
	</xsl:template>

	<xsl:template match="@href" mode="added addedContent deleted deletedContent">
		<xsl:attribute name="href" select="dsd:getResolvedHref(.)"/>
	</xsl:template>
	
	
	<xsl:mode name="unchanged" on-no-match="shallow-copy"/>


	<xsl:template match="/*" mode="unchanged">
		<xsl:copy>
			<xsl:attribute name="xml:base" select="base-uri(.)"/>
			<xsl:apply-templates select="attribute() | node()" mode="#current"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="*[contains(@class, $CLASS_TOPICREF)]/@href" mode="unchanged">
		<xsl:next-match/>
		<xsl:attribute name="dsd:unchanged"/>
	</xsl:template>


	<xsl:template name="changedContent">
		<xsl:param name="isAdded"	as="xs:boolean"/>
		<xsl:param name="content" 	as="node()*"/>

		<xsl:choose>
			<xsl:when test="$isAdded">
				<xsl:attribute name="{$addAttrName}" select="$addAttrVal"/>								
			</xsl:when>
			<xsl:otherwise>
				<xsl:attribute name="{$delAttrName}" select="$delAttrVal"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:sequence select="$content"/>
	</xsl:template>


	<xsl:function name="dsd:getResolvedHref" as="xs:string?">
		<xsl:param name="href" as="attribute()?"/>
		
		<xsl:choose>
			<xsl:when test="empty($href)"/>
			<xsl:when test="starts-with($href, '#')">
				<xsl:value-of select="concat(base-uri($href), $href)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="resolve-uri($href, base-uri($href))"/>		
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
</xsl:stylesheet>
