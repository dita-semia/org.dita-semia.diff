<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
	xmlns:dita-ot	= "http://dita-ot.sourceforge.net/ns/201007/dita-ot"
	xmlns:dsd		= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">


	<xsl:template match="*[contains(@class, $CLASS_TGROUP)]" mode="compareContent">
		<xsl:param name="parent2"	as="node()"/>
		
		<xsl:variable name="parent1" as="element()" select="."/>
		
		<!-- create lcs for columns based on entries of first row. Create a copy of element-only content to ensure stability regarding indention -->
		<xsl:variable name="firstRow1"	as="element()">	<!-- copy without text nodes -->
			<dsd:firstRow>
				<xsl:copy-of select="($parent1/*[contains(@class, $CLASS_THEAD) or contains(@class, $CLASS_TBODY)]/*[contains(@class, $CLASS_ROW)])[1]/*"></xsl:copy-of>
			</dsd:firstRow>
		</xsl:variable>
		<xsl:variable name="firstRow2"	as="element()">
			<dsd:firstRow>
				<xsl:copy-of select="($parent2/*[contains(@class, $CLASS_THEAD) or contains(@class, $CLASS_TBODY)]/*[contains(@class, $CLASS_ROW)])[1]/*"></xsl:copy-of>
			</dsd:firstRow>
		</xsl:variable>
		
		<xsl:variable name="columnsLcs" as="element(lcs)">
			<xsl:call-template name="lcs">
				<xsl:with-param name="parent1" select="$firstRow1"/>
				<xsl:with-param name="parent2" select="$firstRow2"/>
			</xsl:call-template>
		</xsl:variable>
		<!--<xsl:message>columnsLcs: <xsl:sequence select="$columnsLcs"/></xsl:message>-->
		<xsl:variable name="columnsLcs1"	as="xs:integer*" select="tokenize($columnsLcs/@s1, '\s')!xs:integer(.)"/>
		<xsl:variable name="columnsLcs2" 	as="xs:integer*" select="tokenize($columnsLcs/@s2, '\s')!xs:integer(.)"/>
		
		<xsl:variable name="blankEntries"	as="element()">
			<xsl:call-template name="calculateBlankEntries">
				<xsl:with-param name="count1" 	select="count($firstRow1/*)"/>
				<xsl:with-param name="count2" 	select="count($firstRow2/*)"/>
				<xsl:with-param name="lcs1" 	select="$columnsLcs1"/>
				<xsl:with-param name="lcs2" 	select="$columnsLcs2"/>
			</xsl:call-template>
		</xsl:variable>
		<!--<xsl:message>blankEntries: <xsl:sequence select="$blankEntries"/></xsl:message>-->
		<xsl:variable name="blankEntries1"	as="xs:integer*" select="tokenize($blankEntries/@s1, '\s')!xs:integer(.)"/>
		<xsl:variable name="blankEntries2" 	as="xs:integer*" select="tokenize($blankEntries/@s2, '\s')!xs:integer(.)"/>
		
		<!-- merge colspecs using the lcs of the columns -->
		<xsl:variable name="colspecs1" as="element()">
			<dsd:colspecs>
				<xsl:copy-of select="$parent1/*[contains(@class, $CLASS_COLSPEC)]"/>
			</dsd:colspecs>
		</xsl:variable>
		<xsl:variable name="colspecs2" as="element()">
			<dsd:colspecs>
				<xsl:copy-of select="$parent2/*[contains(@class, $CLASS_COLSPEC)]"/>
			</dsd:colspecs>
		</xsl:variable>
		<xsl:call-template name="processContent">
			<xsl:with-param name="parent1" 			select="$colspecs1"/>
			<xsl:with-param name="parent2" 			select="$colspecs2"/>
			<xsl:with-param name="lcs1" 			select="$columnsLcs1"/>
			<xsl:with-param name="lcs2" 			select="$columnsLcs2"/>
			<xsl:with-param name="blankEntries1" 	select="$blankEntries1"	tunnel="yes"/>
			<xsl:with-param name="blankEntries2" 	select="$blankEntries2"	tunnel="yes"/>
		</xsl:call-template>
		
		<!-- handle content except colspec ordinary-->
		<xsl:variable name="content1" as="element()">
			<dsd:content>
				<xsl:copy-of select="$parent1/*[not(contains(@class, $CLASS_COLSPEC))]"/>
			</dsd:content>
		</xsl:variable>
		<xsl:variable name="content2" as="element()">
			<dsd:content>
				<xsl:copy-of select="$parent2/*[not(contains(@class, $CLASS_COLSPEC))]"/>
			</dsd:content>
		</xsl:variable>
		<xsl:call-template name="compareContent">
			<xsl:with-param name="parent1" 			select="$content1"/>
			<xsl:with-param name="parent2" 			select="$content2"/>
			<xsl:with-param name="columnsLcs1" 		select="$columnsLcs1"	tunnel="yes"/>
			<xsl:with-param name="columnsLcs2" 		select="$columnsLcs2"	tunnel="yes"/>
			<xsl:with-param name="blankEntries1" 	select="$blankEntries1"	tunnel="yes"/>
			<xsl:with-param name="blankEntries2" 	select="$blankEntries2"	tunnel="yes"/>
		</xsl:call-template>
	</xsl:template>


	<xsl:template match="*[contains(@class, $CLASS_ROW)]" mode="compareContent">
		<xsl:param name="parent2"		as="node()"/>
		<xsl:param name="columnsLcs1" 	as="xs:integer*"	tunnel="yes"/>
		<xsl:param name="columnsLcs2" 	as="xs:integer*"	tunnel="yes"/>
		
		<xsl:variable name="row1" as="element()">
			<dsd:row id="{@id}">
				<xsl:copy-of select="*"/>
			</dsd:row>
		</xsl:variable>
		<xsl:variable name="row2" as="element()">
			<dsd:row id="{$parent2/@id}">
				<xsl:copy-of select="$parent2/*"/>
			</dsd:row>
		</xsl:variable>
		
		<xsl:call-template name="processContent">
			<xsl:with-param name="parent1" 	select="$row1"/>
			<xsl:with-param name="parent2" 	select="$row2"/>
			<xsl:with-param name="lcs1" 	select="$columnsLcs1"/>
			<xsl:with-param name="lcs2" 	select="$columnsLcs2"/>
			<xsl:with-param name="index"	select="1"/>
		</xsl:call-template>
	</xsl:template>
	
	
	<xsl:template match="*[contains(@class, $CLASS_ROW)]" mode="added">
		<xsl:param  name="blankEntries1"	as="xs:integer*"	tunnel="yes"/>
		
		<!--<xsl:message select="@id"/>-->
		<xsl:variable name="entries" as="element()*" select="*"/>
		<xsl:next-match>
			<xsl:with-param name="content">
				<xsl:for-each select="1 to count($blankEntries1)">
					<xsl:variable name="index" 		as="xs:integer" select="."/>
					<xsl:variable name="xOffset"	as="xs:integer" select="sum($blankEntries1[position() lt $index])"/>
					<xsl:for-each select="0 to $blankEntries1[$index] - 1">
						<xsl:variable name="x" as="xs:integer" select="$index + $xOffset + ."/>
						<!--<xsl:message>index: {$index}, offset: {$xOffset}, x:{$x}</xsl:message>-->
						<entry class="-{$CLASS_ENTRY}" colname="col{$x}" dita-ot:x="{$x}"/>
					</xsl:for-each>
					<xsl:apply-templates select="$entries[$index]" mode="addedContent"/>
				</xsl:for-each>
			</xsl:with-param>
		</xsl:next-match>
	</xsl:template>
	
	
	<xsl:template match="*[contains(@class, $CLASS_ROW)]" mode="deleted">
		<xsl:param  name="blankEntries2"	as="xs:integer*"	tunnel="yes"/>
		
		<xsl:variable name="entries" as="element()*" select="*"/>
		<xsl:next-match>
			<xsl:with-param name="content">
				<xsl:for-each select="1 to count($blankEntries2)">
					<xsl:variable name="index" 		as="xs:integer" select="."/>
					<xsl:variable name="xOffset"	as="xs:integer" select="sum($blankEntries2[position() lt $index])"/>
					<xsl:for-each select="0 to $blankEntries2[$index] - 1">
						<xsl:variable name="x" as="xs:integer" select="$index + $xOffset + ."/>
						<entry class="-{$CLASS_ENTRY}" colname="col{$x}" dita-ot:x="{$x}"/>
					</xsl:for-each>
					<xsl:apply-templates select="$entries[$index]" mode="deletedContent"/>
				</xsl:for-each>
			</xsl:with-param>
		</xsl:next-match>
	</xsl:template>
	
	
	<!-- Calculate the number of blank entries to be inserted before each entry of added/deleted rows -->
	<xsl:template name="calculateBlankEntries" as="element(blankEntries)">
		<xsl:param name="count1" 	as="xs:integer"/>
		<xsl:param name="count2" 	as="xs:integer"/>
		<xsl:param name="lcs1"		as="xs:integer*"/>
		<xsl:param name="lcs2"		as="xs:integer*"/>
		<xsl:param name="index"		as="xs:integer"		select="1"/>
		<xsl:param name="prevPos1"	as="xs:integer" 	select="0"/>
		<xsl:param name="prevPos2"	as="xs:integer" 	select="0"/>
		<xsl:param name="s1"		as="xs:integer*"	select="()"/>
		<xsl:param name="s2"		as="xs:integer*"	select="()"/>

		<xsl:variable name="currPos1"	as="xs:integer?" select="$lcs1[$index]"/>
		<xsl:variable name="currPos2"	as="xs:integer?" select="$lcs2[$index]"/>
		
		<xsl:choose>
			<xsl:when test="$currPos1">
				<xsl:variable name="skip1"	as="xs:integer" select="$currPos1 - $prevPos1 - 1"/>
				<xsl:variable name="skip2"	as="xs:integer" select="$currPos2 - $prevPos2 - 1"/>

				<!-- recurse -->
				<xsl:call-template name="calculateBlankEntries">
					<xsl:with-param name="count1" 	select="$count1"/>
					<xsl:with-param name="count2" 	select="$count2"/>
					<xsl:with-param name="lcs1" 	select="$lcs1"/>
					<xsl:with-param name="lcs2" 	select="$lcs2"/>
					<xsl:with-param name="index"	select="$index + 1"/>
					<xsl:with-param name="prevPos1"	select="$currPos1"/>
					<xsl:with-param name="prevPos2"	select="$currPos2"/>
					<xsl:with-param name="s1"		select="$s1, (for $i in 1 to $skip1 return 0), $skip2"/>
					<xsl:with-param name="s2"		select="$s2, $skip1, (for $i in 1 to $skip2 return 0)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="remain1"	as="xs:integer" select="$count1 - $prevPos1"/>
				<xsl:variable name="remain2"	as="xs:integer" select="$count2 - $prevPos2"/>
				
				<!-- recursion ends -->
				<xsl:element name="blankEntries">
					<xsl:attribute name="s1" select="$s1, (for $i in 1 to $remain1 return 0), $remain2"/>
					<xsl:attribute name="s2" select="$s2, $remain1, (for $i in 1 to $remain2 return 0)"/>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="*[contains(@class, $CLASS_ENTRY)]/@dita-ot:x | *[contains(@class, $CLASS_COLSPEC)]/@colnum" mode="addedContent processMatch unchanged">
		<xsl:param  name="blankEntries1"	as="xs:integer*"	tunnel="yes"/>
		
		<xsl:variable name="index" 		as="xs:integer" select="count(parent::*/preceding-sibling::*) + 1"/>
		<xsl:variable name="xOffset"	as="xs:integer" select="sum($blankEntries1[position() le $index])"/>
		<!--<xsl:message>row: {parent::*/parent::*/@id}, index: {$index}, offset: {$xOffset}, x:{. + $xOffset}</xsl:message>-->
		
		<xsl:attribute name="{name(.)}" select=". + $xOffset"/>
	</xsl:template>
	

	<xsl:template match="*[contains(@class, $CLASS_ENTRY)]/@dita-ot:x | *[contains(@class, $CLASS_COLSPEC)]/@colnum" mode="deletedContent">
		<xsl:param  name="blankEntries2"	as="xs:integer*"	tunnel="yes"/>
		
		<xsl:variable name="index" 		as="xs:integer" select="count(parent::*/preceding-sibling::*) + 1"/>
		<xsl:variable name="xOffset"	as="xs:integer" select="sum($blankEntries2[position() le $index])"/>
		
		<!--<xsl:message>index: {$index}, xOffset: {$xOffset}, x: {. + $xOffset}</xsl:message>-->

		<xsl:attribute name="{name(.)}" select=". + $xOffset"/>
	</xsl:template>
	
</xsl:stylesheet>
