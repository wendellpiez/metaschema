<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="3.0">
    
    <xsl:template name="include-msg" expand-text="true">
        <msg>Finding included XSLT here: { document('')/base-uri(.) }</msg>
    </xsl:template>
    
</xsl:stylesheet>