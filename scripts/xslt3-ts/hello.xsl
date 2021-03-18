<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="3.0">
    
    <xsl:param name="greeting">Hello</xsl:param>

    <xsl:template match="/*" expand-text="true">
        <h1>{ $greeting } World!</h1>
    </xsl:template>
    
</xsl:stylesheet>