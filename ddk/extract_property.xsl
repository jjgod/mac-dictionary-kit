<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" version="1.0" encoding='UTF-8' 
	omit-xml-declaration="yes" indent="no" media-type="text/xml" />

<xsl:template match="/">
	<xsl:apply-templates />
</xsl:template>

<xsl:template match="dict">
	<xsl:for-each select="./*">
		<xsl:text>	</xsl:text>
		<xsl:copy-of select="."/>
		<xsl:text>
</xsl:text>
	</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
