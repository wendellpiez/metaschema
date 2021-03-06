<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:m="http://csrc.nist.gov/ns/oscal/metaschema/1.0"
    xmlns:nm="http://csrc.nist.gov/ns/metaschema"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
    xmlns:oscal="http://csrc.nist.gov/ns/oscal/1.0">

<!-- Extra-XSD validation for NIST Metaschema format 

    This is ISO Schematron with XSLT extensions, requiring 'allow-foreign-namespace' to run.

    x Referential integrity between definitions and references - @ref always resolves
      warnings when flag/@ref points to field|assembly etc
    x Expected appearance of formal-name, description
    x Name usage / name clashes
      x including group-as/@name
    o Stray definitions
      x unused
      o overridden (check interim 'collected' metaschema)
    Inconsistent data type assignments
    Constraints relating to markup-multiline, json-key, json-value-key
    Any other good things from old implementation
    -->

    <sch:ns uri="http://csrc.nist.gov/ns/oscal/metaschema/1.0" prefix="m"/>
    <sch:ns uri="http://csrc.nist.gov/ns/metaschema" prefix="nm"/>
    
    <xsl:import href="metaschema-validation-support.xsl"/>
    
    <xsl:import href="oscal-datatypes-check.xsl"/>
    
    <xsl:variable name="composed-metaschema" select="nm:compose-metaschema(/)"/>
 
    <sch:let name="metaschema-is-abstract" value="/m:METASCHEMA/@abstract='yes'"/>
    
    <sch:pattern id="top-level-and-schema-docs">
        
        <sch:rule context="/m:METASCHEMA">
            <sch:assert test="exists(m:schema-version)" role="warning">Metaschema schema version must be set for any top-level metaschema</sch:assert>
            <sch:assert test="exists(m:define-assembly/m:root-name) or @abstract='yes'">Unless marked as @abstract='yes', a metaschema should have at least one assembly with a root-name.</sch:assert>
        </sch:rule>
        <sch:rule context="/m:METASCHEMA/m:title"/>
        <sch:rule context="/m:METASCHEMA/m:import">
            <sch:report role="warning" test="document-uri(/) = resolve-uri(@href,document-uri(/))">Schema can't import itself</sch:report>
            <sch:assert test="exists(document(@href)/m:METASCHEMA)">Can't find a metaschema at <sch:value-of select="@href"/></sch:assert>
        </sch:rule>
        <sch:rule context="/m:METASCHEMA/m:define-assembly/m:root-name">
            <sch:report test="$metaschema-is-abstract">Assembly should not be defined as a root when /METASCHEMA/@abstract='yes'</sch:report>
        </sch:rule>
        
    </sch:pattern>
    
    
    <sch:pattern id="definitions-and-name-clashes">
        <sch:rule context="m:flag | m:field | m:assembly">
            <sch:let name="aka" value="nm:identifiers(.)"/>
            <sch:let name="def" value="( nm:local-definition-for-reference(.), nm:definition-for-reference(.) )[1]"/>
            <sch:assert test="exists($def)">No definition is given for <sch:name/> '<sch:value-of select="@ref"/>'.</sch:assert>
            <sch:assert test="exists($aka) or empty($def)"><sch:name/> has no name defined (seeing <sch:value-of select="count($aka)"/> for <sch:value-of select="name($def)"/> <sch:value-of select="$def/@name"/>)</sch:assert>
            <sch:let name="siblings" value="(../m:flag | ../m:define-flag | ancestor::m:model[1]/(.|m:choice)/m:field | ancestor::m:model[1]/(.|m:choice)/m:assembly | ancestor::m:model/(.|m:choice)/define-field | ancestor::m:model[1]/(.|m:choice)/m:define-assembly) except ."/>
            <sch:let name="rivals" value="$siblings[nm:identifiers(.) = $aka]"/>
            <sch:assert test="empty($rivals)">Name clash on <sch:name/> using name '<sch:value-of select="$aka"/>'; clashes with neighboring <xsl:value-of select="$rivals/local-name()" separator=", "/></sch:assert>
        </sch:rule>
        
        <sch:rule context="m:METASCHEMA/m:define-assembly | m:METASCHEMA/m:define-field | m:METASCHEMA/m:define-flag">
            <sch:let name="references" value="nm:references-to-definition(.)"/>
            <sch:report test="(name() || '#' || @name)=(../* except .)/(name() || '#' || @name)">Definition for '<sch:value-of select="@name"/>' clashes in this metaschema: not a good idea.</sch:report>
            <!--<sch:assert role="warning" test="exists($references | self::m:define-assembly/m:root-name) and ( not($metaschema-is-abstract or @scope='local') )">-->
            <sch:assert role="warning" test="exists($references | self::m:define-assembly/m:root-name) or $metaschema-is-abstract or (@scope='local')">Orphan <sch:value-of select="substring-after(local-name(),'define-')"/> '<sch:value-of select="@name"/>' is never used in the composed metaschema</sch:assert>
            
            <sch:assert test="not($references/m:group-as/@in-json='BY_KEY') or exists(m:json-key)"><sch:value-of select="substring-after(local-name(),
            'define-')"/> is assigned a json key, but no 'json-key' is given</sch:assert>
            <sch:report test="@name=('RICHTEXT','STRVALUE','PROSE')">Names "STRVALUE", "RICHTEXT" or "PROSE" are reserved.</sch:report>
            
        
        </sch:rule>
        
        <!-- top-level definitions have already matched, so this rule does not apply -->
        <sch:rule context="m:define-assembly | m:define-field">
            <sch:assert test="matches(m:group-as/@name,'\S') or number((@max-occurs,1)[1])=1">Unless @max-occurs is 1, a group name must be given with a local assembly definition.</sch:assert>
        </sch:rule>
        
        
        <sch:rule context="m:group-as">
            <sch:let name="name" value="@name"/>
            <sch:report test="../@max-occurs/number() = 1">"group-as" should not be given when max-occurs is 1.</sch:report>
            <sch:let name="def" value="parent::m:define-field | parent::m:define-assembly | nm:definition-for-reference(parent::*)"/>
            <!--<sch:assert test="count(ancestor::m:model[1]//(m:field | m:define-field | m:assembly | m:define-assembly)[nm:identifiers(.)=$name]) = 1">group-as @name is not unique within this model</sch:assert>-->
            <!-- since definition-for-reference fails on an abstract metaschema we can't perform the json-key check there. -->
            <sch:assert test="$metaschema-is-abstract or not(@in-json='BY_KEY') or $def/m:json-key/@flag-name = $def/(m:flag/@ref|m:define-flag/@name)">Cannot group by key since the definition of <sch:value-of select="name(..)"/> '<sch:value-of select="../@ref"/>' has no json-key specified. Consider adding a json-key to the '<sch:value-of select="../@ref"/>' definition, or using a different 'in-json' setting.</sch:assert>
            <sch:assert test="(@in-json='ARRAY') or not(@in-xml='GROUPED')">When @in-xml='GROUPED', @in-json must be 'ARRAY'.</sch:assert>
        </sch:rule>
        
        </sch:pattern>
    
    <sch:pattern id="flags_and_keys_and_datatypes">
        <sch:rule context="m:field | m:assembly">
            <sch:let name="def" value="( nm:local-definition-for-reference(.), nm:definition-for-reference(.) )[1]"/>
            <!--<sch:report test="exists(nm:local-definition-for-reference(.))"><sch:name/> ref=<sch:value-of select="@ref"/> has local definition</sch:report>-->
            <sch:assert test="empty($def) or (m:group-as/@in-json='BY_KEY') or empty($def/m:json-key)">Target definition for <sch:value-of select="@ref"/> designates a json key, so the invocation should have group-as/@in-json='BY_KEY'</sch:assert>
            <sch:assert test="matches(m:group-as/@name,'\S') or not((@max-occurs/number() gt 1) or (@max-occurs='unbounded'))">Unless @max-occurs is 1, a grouping name (group-as/@name) must be given</sch:assert>

            <!-- constraints related to markup-multiline -->
            <sch:assert test="not(@in-xml='UNWRAPPED') or not($def/@as-type='markup-multiline') or not(preceding-sibling::*[@in-xml='UNWRAPPED']/nm:definition-for-reference(.)/@as-type='markup-multiline')">Only one field may be marked as 'markup-multiline' (without xml wrapping) within a model.</sch:assert>
            <sch:report test="(@in-xml='UNWRAPPED') and (@max-occurs!='1')">An 'unwrapped' field must have a max occurrence of 1</sch:report>
            <sch:assert test="$def/@as-type='markup-multiline' or not(@in-xml='UNWRAPPED')">Only 'markup-multiline' fields may be unwrapped in XML.</sch:assert>
            
        </sch:rule>
        
        <sch:rule context="m:flag | m:define-field/m:define-flag | m:define-assembly/m:define-flag">

            <sch:assert
                test="not((@name | @ref) = ../m:json-value-key/@flag-name) or @required = 'yes'">A flag declared as a value key must be required (@required='yes')</sch:assert>
            <sch:assert
                test="not((@name | @ref) = ../m:json-key/@flag-name) or @required = 'yes'">A flag declared as a key must be required (@required='yes')</sch:assert>
            
            <sch:assert test="not(parent::m:define-field[@as-type='markup-multiline']/nm:references-to-definition(.)/@in-xml='UNWRAPPED')">Multiline markup fields must have no flags, unless always used with a wrapper - put your flags on an assembly with an unwrapped multiline field</sch:assert>
            
        </sch:rule>
        
        <sch:rule context="m:json-key">
            <sch:let name="json-key-flag-name" value="@flag-name"/>
            <sch:let name="json-key-flag" value="../m:flag[@ref=$json-key-flag-name] |../m:define-flag[@name=$json-key-flag-name]"/>
            <sch:assert test="exists($json-key-flag)">JSON key indicates no flag on this <sch:value-of select="substring-after(local-name(..),'define-')"/> <xsl:if test="exists(../m:flag | ../m:define-flag)">Should be (one of) <xsl:value-of select="../m:flag/@ref | ../m:define-flag/@name" separator=", "/></xsl:if></sch:assert>
        </sch:rule>
        
        <sch:rule context="m:json-value-key">
            <sch:assert test="empty(@flag-name) or (@flag-name != ../(m:flag/@ref | m:define-flag/@name) )"><sch:name/> as flag/<sch:value-of select="@flag-name"/> will be inoperative as the value will be given the field key -- no other flags are given <xsl:value-of select="../(m:flag|m:define-flag)/@ref" separator=", "/></sch:assert>
            <sch:report test="exists(@flag-name) and matches(.,'\S')">JSON value key may be set to a value or a flag's value, but not both.</sch:report>
            <sch:assert test="empty(@flag-name) or @flag-name = (../m:flag/@ref|../m:define-flag/@name)">flag '<sch:value-of select="@flag-name"/>' not found for JSON value key</sch:assert>
        </sch:rule>
        
        <sch:rule context="m:allowed-values/m:enum">
            <sch:assert test="not(@value = preceding-sibling::*/@value)">Allowed value '<sch:value-of select="@value"/>' may only be specified once for flag '<sch:value-of select="../../@name"/>'.</sch:assert>
            <sch:assert test="m:datatype-validate(@value,../../@as-type)">Value '<sch:value-of select="@value"/>' is not a valid token of type <sch:value-of select="../../@as-type"/></sch:assert>
        </sch:rule>
        
        <sch:rule context="m:index | m:is-unique">
            <sch:assert test="count(key('index-by-name',@name,$composed-metaschema))=1">Only one index or uniqueness assertion may be named '<sch:value-of select="@name"/>'</sch:assert>
        </sch:rule>
        
        <sch:rule context="m:index-has-key">
            <sch:assert test="count(key('index-by-name',@name,$composed-metaschema)/self::m:index)=1">No '<sch:value-of select="@name"/>' index is defined.</sch:assert>
        </sch:rule>
        
        <sch:rule context="m:key-field">
            <sch:report test="@target = preceding-sibling::*/@target">Index key field target '<sch:value-of select="@target"/>' is already declared.</sch:report>
        </sch:rule>
    </sch:pattern>
    
    <xsl:key name="index-by-name" match="m:index | m:is-unique" use="@name"/>
    
    <sch:pattern id="schema-docs">
        <sch:rule context="m:define-assembly | m:define-field | m:define-flag">
            <sch:assert role="warning" test="exists(m:formal-name)">Formal name missing from <sch:name/></sch:assert>
            <sch:assert role="warning" test="exists(m:description)">Short description missing from <sch:name/></sch:assert>
        </sch:rule>
        
        <sch:rule context="m:p | m:li | m:pre">
            <sch:assert test="matches(.,'\S')">Empty <name/> (is likely to distort rendition)</sch:assert>
            <sch:report role="warning" test="not(matches(.,'\w'))">Not much here is there</sch:report>
        </sch:rule>
    </sch:pattern>
    
      
    <!-- 0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|-->
    
    
    <xsl:key name="definition-by-name" match="m:METASCHEMA/m:define-assembly |
        m:METASCHEMA/m:define-field | m:METASCHEMA/m:define-flag" use="@name"/>
    
    <xsl:key name="definition-for-reference" match="m:METASCHEMA/m:define-assembly" use="@name || ':ASSEMBLY'"/>
    <xsl:key name="definition-for-reference" match="m:METASCHEMA/m:define-field"    use="@name || ':FIELD'"/>
    <xsl:key name="definition-for-reference" match="m:METASCHEMA/m:define-flag"     use="@name || ':FLAG'"/>

    <xsl:key name="references-to-definition" match="m:assembly" use="@ref || ':ASSEMBLY'"/>
    <xsl:key name="references-to-definition" match="m:field"    use="@ref || ':FIELD'"/>
    <xsl:key name="references-to-definition" match="m:flag"     use="@ref || ':FLAG'"/>
    
    <!-- gets back only the appropriate global definition for an assembly, field or flag   -->
    <xsl:function name="nm:definition-for-reference" as="element()?">
        <xsl:param name="who" as="element()"/>
        <xsl:variable name="really-who" select="$who/(self::m:assembly | self::m:field | self::m:flag)"/>
        <xsl:variable name="tag" expand-text="true">{ $really-who/@ref }:{ local-name($really-who) => upper-case() }</xsl:variable>
        <xsl:sequence select="key('definition-for-reference',$tag,$composed-metaschema)"/>
    </xsl:function>
    
    <xsl:function name="nm:local-definition-for-reference" as="element()?">
        <xsl:param name="who" as="element()"/>
        <xsl:variable name="really-who" select="$who/(self::m:assembly | self::m:field | self::m:flag)"/>
        <xsl:variable name="tag" expand-text="true">{ $really-who/@ref }:{ local-name($really-who) => upper-case() }</xsl:variable>
        <xsl:sequence select="key('definition-for-reference',$tag,$who/root())[@scope='local']"/>
    </xsl:function>
    
    <xsl:function name="nm:references-to-definition" as="element()*">
        <!-- expects define-assembly, define-field or define-flag -->
        <xsl:param name="who" as="element()"/>
        <xsl:variable name="really-who" select="$who/(self::m:define-assembly | self::m:define-field | self::m:define-flag)"/>
        <xsl:variable name="tag" expand-text="true">{ $really-who/@name }:{ substring-after(local-name($really-who),'define-') => upper-case() }</xsl:variable>
        <xsl:sequence select="$really-who/key('references-to-definition',$tag,$composed-metaschema)"/>
    </xsl:function>
    
   <!-- <xsl:template mode="nm:get-references" match="m:define-assembly | m:define-field | m:define-flag">
        <xsl:variable name="tag" expand-text="true">:{ substring-after(local-name(.),'define-') => upper-case() }</xsl:variable>
    </xsl:template>-->
    
    
    <xsl:function name="nm:sort" as="item()*">
        <xsl:param name="seq" as="item()*"/>
        <xsl:for-each select="$seq">
            <xsl:sort select="."/>
            <xsl:sequence select="."/>
        </xsl:for-each>
    '</xsl:function>
    
    
    <xsl:function name="nm:identifiers" as="xs:string*">
        <xsl:param name="who" as="element()"/>
        <xsl:apply-templates select="$who" mode="nm:get-identifiers"/>
    </xsl:function>
    
    <xsl:template match="m:define-assembly | m:define-field | m:define-flag" mode="nm:get-identifiers">
        <xsl:sequence select="m:root-name,(m:use-name,@name)[1], m:group-as/@name"/>
        <!--<xsl:message expand-text="true">{ @name }</xsl:message>-->
    </xsl:template>
    
    <xsl:template priority="3" match="m:assembly[exists(m:use-name)] |
                         m:field[exists(m:use-name)] |
                         m:flag[exists(m:use-name)]" mode="nm:get-identifiers">
        <xsl:sequence select="m:use-name, m:group-as/@name"/>
    </xsl:template>
    
    <xsl:template priority="2" match="*[exists(nm:definition-for-reference(.))]" mode="nm:get-identifiers">
        <xsl:sequence select="m:group-as/@name"/>
        <xsl:apply-templates select="nm:definition-for-reference(.)" mode="#current"/>
    </xsl:template>
    
    <xsl:template priority="1" match="*[exists(nm:local-definition-for-reference(.))]" mode="nm:get-identifiers">
        <xsl:sequence select="m:group-as/@name"/>
        <xsl:apply-templates select="nm:local-definition-for-reference(.)" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="*" mode="nm:get-identifiers"/>
    
</sch:schema>