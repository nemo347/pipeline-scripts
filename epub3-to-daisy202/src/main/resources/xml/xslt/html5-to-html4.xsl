<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:f="http://www.daisy.org/ns/pipeline/internal-functions" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns="http://www.w3.org/1999/xhtml"
    xpath-default-namespace="http://www.w3.org/1999/xhtml" exclude-result-prefixes="#all" xmlns:epub="http://www.idpf.org/2007/ops" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema">

    <xsl:output indent="yes" exclude-result-prefixes="#all"/>

    <xsl:variable name="all-ids" select="//@id"/>

    <xsl:template match="text()|comment()">
        <xsl:copy-of select="."/>
    </xsl:template>

    <xsl:template match="*">
        <xsl:comment select="concat('No template for element: ',name())"/>
    </xsl:template>

    <xsl:template match="html:style"/>
    <xsl:template name="coreattrs">
        <xsl:param name="except" tunnel="yes"/>

        <xsl:copy-of select="(@id|@title|@xml:space)[not(name()=$except)]"/>
        <xsl:call-template name="classes-and-types"/>
    </xsl:template>

    <xsl:template name="i18n">
        <xsl:param name="except" tunnel="yes"/>

        <xsl:copy-of select="(@dir)[not(name()=$except)]"/>
        <xsl:if test="(@xml:lang|@lang) and not(('xml:lang','lang')=$except)">
            <xsl:attribute name="xml:lang" select="(@xml:lang|@lang)[1]"/>
        </xsl:if>
    </xsl:template>

    <xsl:template name="classes-and-types">
        <xsl:param name="classes" select="()" tunnel="yes"/>
        <xsl:param name="except" tunnel="yes" select="()"/>
        <xsl:param name="except-classes" tunnel="yes" select="()"/>

        <xsl:if test="not($except-classes='*')">

            <xsl:variable name="old-classes" select="f:classes(.)"/>

            <xsl:variable name="showin" select="replace($old-classes[matches(.,'^showin-...$')][1],'showin-','')"/>
            <xsl:if test="$showin and not('_showin'=$except)">
                <xsl:attribute name="showin" select="$showin"/>
            </xsl:if>

            <xsl:if test="not('_class'=$except)">
                <xsl:variable name="epub-type-classes">
                    <xsl:for-each select="f:types(.)[not(matches(.,'(^|:)(front|body|back)matter'))]">
                        <xsl:choose>
                            <xsl:when test=".='cover'">
                                <!-- TODO: add epub:types that maps to different class strings here like this -->
                                <xsl:sequence select="'jacketcopy'"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="tokenize(.,':')[last()]"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:variable>

                <xsl:variable name="class-string"
                    select="string-join(distinct-values(($classes, if (preceding-sibling::*[1] intersect preceding-sibling::html:hr[1]) then 'precedingemptyline' else (), $old-classes[not(matches(.,concat('showin-',$showin)))], $epub-type-classes)[not(.='') and not(.=$except-classes)]),' ')"/>
                <xsl:if test="not($class-string='')">
                    <xsl:attribute name="class" select="$class-string"/>
                </xsl:if>
            </xsl:if>

        </xsl:if>
    </xsl:template>

    <xsl:template name="attrs">
        <xsl:call-template name="coreattrs"/>
        <xsl:call-template name="i18n"/>
    </xsl:template>

    <xsl:template name="attrsrqd">
        <xsl:param name="except" tunnel="yes"/>

        <xsl:copy-of select="(@id|@title|@xml:space)[not(name()=$except)]"/>
        <xsl:call-template name="classes-and-types"/>
        <xsl:call-template name="i18n"/>
    </xsl:template>

    <xsl:template match="html:html">
        <dtbook version="2005-3">
            <xsl:call-template name="attlist.dtbook"/>
            <xsl:apply-templates select="node()"/>
        </dtbook>
    </xsl:template>

    <xsl:template name="attlist.dtbook">
        <xsl:call-template name="i18n"/>
    </xsl:template>

    <xsl:template match="html:head">
        <head>
            <xsl:call-template name="attlist.head"/>
            <meta name="dtb:uid" content="{(html:meta[lower-case(@name)=('dtb:uid','dc:identifier')])[1]/@content}"/>
            <xsl:apply-templates select="node()"/>
            <!-- TODO: maybe add some default CSS styles here? -->
        </head>
    </xsl:template>

    <xsl:template match="html:title">
        <meta name="dc:Title" content="{normalize-space(.)}">
            <xsl:call-template name="i18n"/>
        </meta>
    </xsl:template>

    <xsl:template name="attlist.head">
        <xsl:call-template name="i18n"/>
        <xsl:if test="html:link[@rel='profile' and @href]">
            <xsl:attribute name="profile" select="(html:link[@rel='profile'][1])/@href"/>
        </xsl:if>
    </xsl:template>

    <!-- link is disallowed in nordic DTBook -->
    <xsl:template match="html:link">
        <!--<link>
            <xsl:call-template name="attlist.link"/>
        </link>-->
    </xsl:template>

    <xsl:template name="attlist.link">
        <xsl:call-template name="attrs"/>
        <xsl:copy-of select="@href|@hreflang|@type|@rel|@media"/>
        <!-- @sizes are dropped -->
    </xsl:template>

    <xsl:template match="html:meta">
        <xsl:message
            select="concat('removed meta element because it did not contain a name attribute, a content attribute, or for some other reason (',string-join(for $a in (@*) return concat($a/name(),'=&quot;',$a,'&quot;'),' '),')')"
        />
    </xsl:template>

    <xsl:template match="html:meta[@name and @content and not(lower-case(@name)=('viewport','dc:title'))]">
        <meta>
            <xsl:call-template name="attlist.meta"/>
        </meta>
    </xsl:template>

    <xsl:template name="attlist.meta">
        <xsl:call-template name="i18n"/>
        <xsl:copy-of select="@http-equiv"/>
        <xsl:choose>
            <xsl:when test="@name='nordic:guidelines'">
                <xsl:attribute name="name" select="'track:Guidelines'"/>
                <xsl:attribute name="content" select="'2011-2'"/>
            </xsl:when>
            <xsl:when test="lower-case(@name)='dc:format'">
                <xsl:attribute name="name" select="'dc:Format'"/>
                <xsl:attribute name="content" select="'DTBook'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="name" select="if (starts-with(@name,'dc:')) then concat('dc:',upper-case(substring(@name,4,1)),lower-case(substring(@name,5))) else @name"/>
                <xsl:attribute name="content" select="@content"/>
            </xsl:otherwise>
        </xsl:choose>
        <!-- @charset is dropped -->
    </xsl:template>

    <xsl:template match="html:body">
        <book>
            <xsl:if test="(html:section | html:article)[f:types(.)=('cover','frontmatter')] or *[not(self::html:section)]">
                <xsl:call-template name="frontmatter"/>
            </xsl:if>
            <xsl:if test="(html:section | html:article)[f:types(.)=('bodymatter') or not(f:types(.)=('cover','frontmatter','bodymatter','backmatter'))]">
                <xsl:call-template name="bodymatter"/>
            </xsl:if>
            <xsl:if test="(html:section | html:article)[f:types(.)=('backmatter')]">
                <xsl:call-template name="rearmatter"/>
            </xsl:if>
            <xsl:apply-templates select="*[last()]/following-sibling::node()"/>
        </book>
    </xsl:template>

    <xsl:template name="frontmatter">
        <xsl:call-template name="copy-preceding-comments"/>
        <frontmatter>
            <xsl:for-each select="html:header">
                <xsl:call-template name="copy-preceding-comments"/>
                <xsl:apply-templates select="node()"/>
            </xsl:for-each>
            <xsl:apply-templates select="(html:section | html:article)[f:types(.)=('cover','frontmatter')]"/>
        </frontmatter>
    </xsl:template>

    <xsl:template name="bodymatter">
        <bodymatter>
            <xsl:apply-templates select="(html:section | html:article)[not(f:types(.)=('cover','frontmatter','backmatter'))]"/>
        </bodymatter>
    </xsl:template>

    <xsl:template name="rearmatter">
        <rearmatter>
            <xsl:apply-templates select="(html:section | html:article)[f:types(.)=('backmatter')]"/>
        </rearmatter>
    </xsl:template>

    <xsl:template match="html:section | html:article">
        <xsl:call-template name="copy-preceding-comments"/>
        <xsl:variable name="level" select="f:level(.)"/>
        <xsl:element name="level{f:level(.)}">
            <xsl:call-template name="attlist.level">
                <xsl:with-param name="classes" select="if (self::html:article) then 'article' else ()" tunnel="yes"/>
                <!--<xsl:with-param name="level-classes"
                    select="if ($level &gt; 1) then () else (if (f:types(.)='cover') then 'jacketcopy' else (), for $class in (tokenize(@class,'\s')) return if ($class = ('part','jacketcopy','colophon','nonstandardpagination')) then $class else ())"
                />-->
            </xsl:call-template>

            <xsl:variable name="headline" select="(html:*[matches(local-name(),'^h\d$')])[1]"/>

            <xsl:choose>
                <xsl:when test="not($headline/preceding-sibling::*[1][f:types(.)='pagebreak']) and $headline/following-sibling::*[1][f:types(.)='pagebreak']">
                    <!-- [tpb126] pagenum must not occur directly after hx unless the hx is preceded by a pagenum -->
                    <xsl:variable name="initial-pagebreak" select="$headline/following-sibling::*[1][f:types(.)='pagebreak']"/>
                    <xsl:apply-templates select="$initial-pagebreak"/>
                    <xsl:apply-templates select="$headline"/>
                    <xsl:apply-templates select="node()[not(. intersect $initial-pagebreak) and not(. intersect $headline)]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="node()"/>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:element>
    </xsl:template>

    <xsl:template name="attlist.level">
        <!--        <xsl:param name="level-classes"/>-->
        <xsl:call-template name="attrs">
            <!--            <xsl:with-param name="except-classes" select="'*'" tunnel="yes"/>-->
        </xsl:call-template>
        <!--<xsl:if test="count($level-classes) &gt; 0">
            <xsl:attribute name="class" select="string-join($level-classes,' ')"/>
        </xsl:if>-->
    </xsl:template>

    <xsl:template match="html:br">
        <br>
            <xsl:call-template name="attlist.br"/>
        </br>
    </xsl:template>

    <xsl:template name="attlist.br">
        <xsl:call-template name="coreattrs"/>
    </xsl:template>

    <xsl:template match="html:p[f:classes(.)='line']">
        <line>
            <xsl:call-template name="attlist.line"/>
            <xsl:apply-templates select="node()"/>
        </line>
    </xsl:template>

    <xsl:template name="attlist.line">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="'line'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="html:span[f:classes(.)='linenum']">
        <linenum>
            <xsl:call-template name="attlist.linenum"/>
            <xsl:apply-templates select="node()"/>
        </linenum>
    </xsl:template>

    <xsl:template name="attlist.linenum">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="'linenum'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <!-- <address> is not allowed in nordic DTBook. Replacing with p. -->
    <xsl:template match="html:address">
        <xsl:message select="'&lt;address&gt; is not allowed in nordic DTBook. Replacing with p and a &quot;address&quot; class.'"/>
        <p>
            <xsl:call-template name="attlist.address"/>
            <xsl:apply-templates select="node()"/>
        </p>
    </xsl:template>

    <!-- <address> is not allowed in nordic DTBook. Replacing with p and a "address" class. -->
    <xsl:template name="attlist.address">
        <xsl:call-template name="attrs">
            <xsl:with-param name="classes" select="'address'" tunnel="yes"/>
            <!--            <xsl:with-param name="except-classes" select="'*'" tunnel="yes"/>-->
            <!--            <xsl:with-param name="except-classes" select="'address'" tunnel="yes"/>-->
        </xsl:call-template>
        <xsl:call-template name="attlist.p.class"/>
    </xsl:template>

    <xsl:template match="html:div">
        <div>
            <xsl:call-template name="attlist.div"/>
            <xsl:apply-templates select="node()"/>
        </div>
    </xsl:template>

    <xsl:template name="attlist.div">
        <xsl:call-template name="attrs"/>
    </xsl:template>

    <xsl:template match="html:*[f:classes(.)='title']">
        <title>
            <xsl:call-template name="attlist.title"/>
            <xsl:apply-templates select="node()"/>
        </title>
    </xsl:template>

    <xsl:template name="attlist.title">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="'title'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="html:*[f:types(.)='z3998:author' and not(parent::html:header[parent::html:body])]">
        <author>
            <xsl:call-template name="attlist.author"/>
            <xsl:apply-templates select="node()"/>
        </author>
    </xsl:template>

    <xsl:template name="attlist.author">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="'author'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="html:aside[f:types(.)='z3998:production']">
        <prodnote>
            <xsl:call-template name="attlist.prodnote"/>
            <xsl:apply-templates select="node()"/>
        </prodnote>
    </xsl:template>

    <xsl:template name="attlist.prodnote">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="('production','render-required','render-optional')" tunnel="yes"/>
        </xsl:call-template>
        <xsl:choose>
            <xsl:when test="f:classes(.)='render-required'">
                <xsl:attribute name="render" select="'required'"/>
            </xsl:when>
            <xsl:when test="f:classes(.)='render-optional'">
                <xsl:attribute name="render" select="'optional'"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- let's make "optional" the default -->
                <xsl:attribute name="render" select="'optional'"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="@id">
            <xsl:variable name="id" select="@id"/>
            <xsl:variable name="img" select="//html:img[replace(@longdesc,'^#','')=$id]"/>
            <xsl:if test="$img">
                <xsl:attribute name="imgref" select="string-join($img/((@id,f:generate-pretty-id(.))[1]),' ')"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:template match="html:aside[f:types(.)='sidebar']">
        <sidebar>
            <xsl:call-template name="attlist.sidebar"/>
            <xsl:apply-templates select="node()"/>
        </sidebar>
    </xsl:template>

    <xsl:template name="attlist.sidebar">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="('sidebar','render-required','render-optional')" tunnel="yes"/>
        </xsl:call-template>
        <xsl:choose>
            <xsl:when test="f:classes(.)='render-required'">
                <xsl:attribute name="render" select="'required'"/>
            </xsl:when>
            <xsl:when test="f:classes(.)='render-optional'">
                <xsl:attribute name="render" select="'optional'"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- let's make "optional" the default -->
                <xsl:attribute name="render" select="'optional'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="html:aside[f:types(.)='note']">
        <note>
            <xsl:call-template name="attlist.note"/>
            <xsl:apply-templates select="node()"/>
        </note>
    </xsl:template>

    <xsl:template name="attlist.note">
        <xsl:call-template name="attrsrqd">
            <xsl:with-param name="except-classes" select="'*'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <!-- <annotation> is not allowed in nordic DTBook. Replacing with p. -->
    <xsl:template match="html:aside[f:types(.)='annotation']">
        <xsl:message select="'&lt;annotation&gt; is not allowed in nordic DTBook. Replacing with p and a &quot;annotation&quot; class.'"/>
        <p>
            <xsl:call-template name="attlist.annotation"/>
            <xsl:apply-templates select="node()"/>
        </p>
    </xsl:template>

    <!-- <annotation> is not allowed in nordic DTBook. Replacing with p and a "annotation" class. -->
    <xsl:template name="attlist.annotation">
        <xsl:call-template name="attrsrqd">
            <xsl:with-param name="classes" select="'annotation'" tunnel="yes"/>
            <!--            <xsl:with-param name="except-classes" select="'*'" tunnel="yes"/>-->
            <!--            <xsl:with-param name="except-classes" select="'annotation'" tunnel="yes"/>-->
        </xsl:call-template>
        <xsl:call-template name="attlist.p.class"/>
    </xsl:template>

    <!-- <epigraph> is not allowed in nordic DTBook. Using p instead. -->
    <xsl:template match="html:aside[f:types(.)='epigraph']">
        <xsl:message select="'&lt;epigraph&gt; is not allowed in nordic DTBook. Using p instead with a epigraph class.'"/>
        <p>
            <xsl:call-template name="attlist.epigraph"/>
            <xsl:apply-templates select="node()"/>
        </p>
    </xsl:template>

    <!-- <epigraph> is not allowed in nordic DTBook. Using div instead with a epigraph class. -->
    <xsl:template name="attlist.epigraph">
        <xsl:call-template name="attrs">
            <xsl:with-param name="classes" select="'epigraph'" tunnel="yes"/>
            <!--            <xsl:with-param name="except-classes" select="'*'" tunnel="yes"/>-->
            <!--            <xsl:with-param name="except-classes" select="'epigraph'" tunnel="yes"/>-->
        </xsl:call-template>
        <xsl:call-template name="attlist.p.class"/>
    </xsl:template>

    <!-- <byline> is not allowed in nordic DTBook. Using span instead. -->
    <xsl:template match="html:span[f:classes(.)='byline']">
        <xsl:message select="'&lt;byline&gt; is not allowed in nordic DTBook. Using span instead with a byline class.'"/>
        <span>
            <xsl:call-template name="attlist.byline"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <!-- <byline> is not allowed in nordic DTBook. Using span instead with a byline class. -->
    <xsl:template name="attlist.byline">
        <xsl:call-template name="attrs">
            <!--            <xsl:with-param name="except-classes" select="'byline'" tunnel="yes"/>-->
        </xsl:call-template>
    </xsl:template>

    <!-- <dateline> is not allowed in nordic DTBook. Using span instead. -->
    <xsl:template match="html:span[f:classes(.)='dateline']">
        <xsl:message select="'&lt;dateline&gt; is not allowed in nordic DTBook. Using span instead with a dateline class.'"/>
        <span>
            <xsl:call-template name="attlist.dateline"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <!-- <dateline> is not allowed in nordic DTBook. Using span instead with a dateline class. -->
    <xsl:template name="attlist.dateline">
        <xsl:call-template name="attrs">
            <!--            <xsl:with-param name="except-classes" select="'dateline'" tunnel="yes"/>-->
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="html:*[f:classes(.)='linegroup']">
        <linegroup>
            <xsl:call-template name="attlist.linegroup"/>
            <xsl:apply-templates select="node()"/>
        </linegroup>
    </xsl:template>

    <xsl:template name="attlist.linegroup">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="'linegroup'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="html:*[f:types(.)='z3998:poem']">
        <poem>
            <xsl:call-template name="attlist.poem"/>
            <xsl:apply-templates select="node()"/>
        </poem>
    </xsl:template>

    <xsl:template name="attlist.poem">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="'poem'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <!-- <a> is not allowed in nordic DTBook. Replacing with span. -->
    <xsl:template match="html:a">
        <xsl:message select="'&lt;a&gt; is not allowed in nordic DTBook. Replacing with span and a &quot;a&quot; class.'"/>
        <span>
            <xsl:call-template name="attlist.a"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <!-- <a> is not allowed in nordic DTBook. Replacing with span and a "a" class. -->
    <xsl:template name="attlist.a">
        <xsl:call-template name="attrs">
            <!-- Preserve @target as class attribute. Assumes that only characters that are valid for class names are used. -->
            <xsl:with-param name="classes" select="('a', if (@target) then concat('target-',replace(@target,'_','-')) else ())" tunnel="yes"/>
            <xsl:with-param name="except-classes" select="('external-true','external-false',for $rev in (f:classes(.)[matches(.,'^rev-')]) return $rev )" tunnel="yes"/>
        </xsl:call-template>
        <!--<xsl:copy-of select="@type|@href|@hreflang|@rel|@accesskey|@tabindex"/>
        <!-\- @download and @media is dropped - they don't have a good equivalent in DTBook -\->

        <xsl:choose>
            <xsl:when test="f:classes(.)[matches(.,'^external-(true|false)')]">
                <xsl:attribute name="external" select="replace((f:classes(.)[matches(.,'^external-(true|false)')])[1],'^external-','')"/>
            </xsl:when>
            <xsl:when test="@target='_blank' or matches(@href,'^(\w+:|/)')">
                <xsl:attribute name="external" select="'true'"/>
            </xsl:when>
        </xsl:choose>

        <xsl:if test="f:classes(.)[matches(.,'^rev-')]">
            <xsl:attribute name="rev" select="replace((f:classes(.)[matches(.,'^rev-')])[1],'^rev-','')"/>
        </xsl:if>-->
    </xsl:template>

    <xsl:template match="html:em">
        <em>
            <xsl:call-template name="attlist.em"/>
            <xsl:apply-templates select="node()"/>
        </em>
    </xsl:template>

    <xsl:template name="attlist.em">
        <xsl:call-template name="attrs"/>
    </xsl:template>

    <xsl:template match="html:strong">
        <strong>
            <xsl:call-template name="attlist.strong"/>
            <xsl:apply-templates select="node()"/>
        </strong>
    </xsl:template>

    <xsl:template name="attlist.strong">
        <xsl:call-template name="attrs"/>
    </xsl:template>

    <!-- <dfn> is not allowed in nordic DTBook. Replacing with span. -->
    <xsl:template match="html:dfn">
        <xsl:message select="'&lt;dfn&gt; is not allowed in nordic DTBook. Replacing with span and a &quot;definition&quot; class.'"/>
        <span>
            <xsl:call-template name="attlist.dfn"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <!-- <dfn> is not allowed in nordic DTBook. Replacing with span and a "definition" class. -->
    <xsl:template name="attlist.dfn">
        <xsl:call-template name="attrs">
            <xsl:with-param name="classes" select="'definition'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <!-- <kbd> is not allowed in nordic DTBook. Replacing with code. -->
    <xsl:template match="html:kbd">
        <xsl:message select="'&lt;kbd&gt; is not allowed in Nordic DTBook. Replacing with &lt;code&gt; and a &quot;keyboard&quot; class.'"/>
        <code>
            <xsl:call-template name="attlist.kbd"/>
            <xsl:apply-templates select="node()"/>
        </code>
    </xsl:template>

    <!-- <kbd> is not allowed in nordic DTBook. Replacing with code and a "keyboard" class. -->
    <xsl:template name="attlist.kbd">
        <xsl:call-template name="attrs">
            <xsl:with-param name="classes" select="'keyboard'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="html:code">
        <code>
            <xsl:call-template name="attlist.code"/>
            <xsl:apply-templates select="node()"/>
        </code>
    </xsl:template>

    <xsl:template name="attlist.code">
        <xsl:call-template name="attrs"/>
        <xsl:call-template name="i18n"/>
    </xsl:template>

    <!-- <samp> is not allowed in nordic DTBook. Replacing with code. -->
    <xsl:template match="html:samp">
        <xsl:message select="'&lt;samp&gt; is not allowed in nordic DTBook. Replacing with code and a &quot;example&quot; class.'"/>
        <code>
            <xsl:call-template name="attlist.samp"/>
            <xsl:apply-templates select="node()"/>
        </code>
    </xsl:template>

    <!-- <samp> is not allowed in nordic DTBook. Replacing with code and a "example" class. -->
    <xsl:template name="attlist.samp">
        <xsl:call-template name="attrs">
            <xsl:with-param name="classes" select="'example'" tunnel="yes"/>
        </xsl:call-template>
        <xsl:call-template name="i18n"/>
    </xsl:template>

    <!-- <cite> is not allowed in nordic DTBook. Using span instead. -->
    <xsl:template match="html:cite">
        <xsl:message select="'&lt;cite&gt; is not allowed in nordic DTBook. Using span instead with a cite class.'"/>
        <span>
            <xsl:call-template name="attlist.cite"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <!-- <cite> is not allowed in nordic DTBook. Using span instead with a cite class. -->
    <xsl:template name="attlist.cite">
        <xsl:call-template name="attrs">
            <xsl:with-param name="classes" select="'cite'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <!-- abbr is disallowed in nordic dtbooks, using span instead -->
    <xsl:template match="html:abbr">
        <span>
            <xsl:call-template name="attlist.abbr"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <xsl:template name="attlist.abbr">
        <xsl:call-template name="attrs">
            <xsl:with-param name="classes" select="'abbr'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <!-- acronym is disallowed in nordic dtbooks, using span instead -->
    <xsl:template match="html:abbr[f:types(.)='z3998:acronym']">
        <span>
            <xsl:call-template name="attlist.acronym"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <!-- acronym is disallowed in nordic dtbooks, using span instead and thus not setting the pronounce attribute -->
    <xsl:template name="attlist.acronym">
        <xsl:call-template name="attrs">
            <xsl:with-param name="classes" select="'acronym'" tunnel="yes"/>
        </xsl:call-template>
        <!--<xsl:if test="f:classes(.)='spell-out' or matches(@style,'-epub-speak-as:\s*spell-out')">
            <xsl:attribute name="pronounce" select="'no'"/>
        </xsl:if>-->
    </xsl:template>

    <xsl:template match="html:sub">
        <sub>
            <xsl:call-template name="attlist.sub"/>
            <xsl:apply-templates select="node()"/>
        </sub>
    </xsl:template>

    <xsl:template name="attlist.sub">
        <xsl:call-template name="attrs"/>
    </xsl:template>

    <xsl:template match="html:sup">
        <sup>
            <xsl:call-template name="attlist.sup"/>
            <xsl:apply-templates select="node()"/>
        </sup>
    </xsl:template>

    <xsl:template name="attlist.sup">
        <xsl:call-template name="attrs"/>
    </xsl:template>

    <xsl:template match="html:span">
        <span>
            <xsl:call-template name="attlist.span"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <xsl:template name="attlist.span">
        <xsl:call-template name="attrs"/>
    </xsl:template>

    <!-- <bdo> is not allowed in nordic DTBook. Replacing with span. -->
    <xsl:template match="html:bdo">
        <xsl:message select="'&lt;bdo&gt; is not allowed in nordic DTBook. Replacing with span and a &quot;bdo-dir-{@dir}&quot; class.'"/>
        <span>
            <xsl:call-template name="attlist.bdo"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <!-- <bdo> is not allowed in nordic DTBook. Replacing with span and a "bdo-dir-{@dir}" class. -->
    <xsl:template name="attlist.bdo">
        <xsl:call-template name="coreattrs">
            <xsl:with-param name="classes" select="('bdo', if (@dir and not(@dir='')) then concat('bdo-dir-',@dir) else ())" tunnel="yes"/>
        </xsl:call-template>
        <xsl:call-template name="i18n"/>
    </xsl:template>

    <!-- <sent> not allowed in nordic guidelines, using <span> instead -->
    <xsl:template match="html:span[f:types(.)='z3998:sentence']">
        <span>
            <xsl:call-template name="attlist.sent"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <!-- <sent> not allowed in nordic guidelines, using <span> instead and including the 'sentence' type as a class -->
    <!--            <xsl:with-param name="except-classes" select="'sentence'" tunnel="yes"/>-->
    <xsl:template name="attlist.sent">
        <xsl:call-template name="attrs"/>
    </xsl:template>

    <!-- <w> is not allowed in nordic DTBook. Using span instead. -->
    <xsl:template match="html:span[f:types(.)='z3998:word' and not(f:types(.)='z3998:sentence')]">
        <xsl:message select="'&lt;w&gt; is not allowed in nordic DTBook. Using span instead with a &quot;word&quot; class.'"/>
        <span>
            <xsl:call-template name="attlist.w"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <!-- <w> is not allowed in nordic DTBook. Using span instead with a "word" class. -->
    <xsl:template name="attlist.w">
        <xsl:call-template name="attrs">
            <!--            <xsl:with-param name="except-classes" select="'word'" tunnel="yes"/>-->
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="html:*[self::html:span or self::html:div][f:types(.)='pagebreak']">
        <pagenum>
            <xsl:call-template name="attlist.pagenum"/>
            <xsl:value-of select="@title"/>
        </pagenum>
    </xsl:template>

    <xsl:template name="attlist.pagenum">
        <xsl:call-template name="attrsrqd">
            <xsl:with-param name="except" select="'title'" tunnel="yes"/>
            <xsl:with-param name="except-classes" select="('page-front','page-normal','page-special','pagebreak')" tunnel="yes"/>
        </xsl:call-template>
        <xsl:attribute name="page" select="replace((f:classes(.)[starts-with(.,'page-')],'page-normal')[1], '^page-', '')"/>
    </xsl:template>

    <xsl:template match="html:a[f:types(.)='noteref']">
        <noteref>
            <xsl:call-template name="attlist.noteref"/>
            <xsl:apply-templates select="node()"/>
        </noteref>
    </xsl:template>

    <xsl:template name="attlist.noteref">
        <xsl:if test="@class or @epub:type">
            <xsl:message select="'the class attribute on a noteref was dropped since it is not allowed in Nordic DTBook.'"/>
        </xsl:if>
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="'*'" tunnel="yes"/>
        </xsl:call-template>
        <xsl:attribute name="idref" select="@href"/>
        <xsl:copy-of select="@type"/>
    </xsl:template>

    <!-- <annoref> is not allowed in nordic DTBook. Replacing with span. -->
    <xsl:template match="html:a[f:types(.)='annoref']">
        <xsl:message select="'&lt;annoref&gt; is not allowed in nordic DTBook. Replacing with span and a &quot;annoref&quot; class.'"/>
        <span>
            <xsl:call-template name="attlist.annoref"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <!-- <annoref> is not allowed in nordic DTBook. Replacing with span and a "annoref" class. -->
    <xsl:template name="attlist.annoref">
        <xsl:call-template name="attrs">
            <!--            <xsl:with-param name="except-classes" select="'annoref'" tunnel="yes"/>-->
        </xsl:call-template>
        <!--<xsl:attribute name="idref" select="@href"/>
        <xsl:copy-of select="@type"/>-->
    </xsl:template>

    <!-- <q> is not allowed in nordic DTBook. Replacing with span. -->
    <xsl:template match="html:q">
        <xsl:message select="'&lt;q&gt; is not allowed in nordic DTBook. Replacing with span and a &quot;quote&quot; class.'"/>
        <span>
            <xsl:call-template name="attlist.q"/>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <!-- <q> is not allowed in nordic DTBook. Replacing with span and a "quote" class. -->
    <xsl:template name="attlist.q">
        <xsl:call-template name="attrs">
            <xsl:with-param name="classes" select="'quote'" tunnel="yes"/>
        </xsl:call-template>
        <!--        <xsl:copy-of select="@cite"/>-->
    </xsl:template>

    <xsl:template match="html:img">
        <img>
            <xsl:call-template name="attlist.img"/>
            <xsl:apply-templates select="node()"/>
        </img>
    </xsl:template>

    <xsl:template name="attlist.img">
        <xsl:call-template name="attrs"/>
        <xsl:attribute name="src" select="replace(@src,'^images/','')"/>
        <xsl:copy-of select="@alt|@longdesc|@height|@width"/>
        <xsl:if test="not(@id)">
            <xsl:attribute name="id" select="f:generate-pretty-id(.)"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="html:figure">
        <imggroup>
            <xsl:call-template name="attlist.imggroup"/>
            <xsl:choose>
                <xsl:when test="not(html:figcaption) or html:figcaption/*[not(self::html:div[f:classes(.)='img-caption'])]">
                    <!-- no figcaption present or figcaption does not follow the convention that lets it be matched against individual images -->
                    <xsl:apply-templates select="node()"/>
                </xsl:when>

                <xsl:otherwise>
                    <xsl:variable name="precede" select="if (html:img[1]/preceding-sibling::html:figcaption) then true() else false()"/>
                    <xsl:for-each select="node()[not(self::html:figcaption)]">
                        <xsl:choose>
                            <xsl:when test="self::html:img">
                                <xsl:variable name="position" select="count(preceding-sibling::html:img)+1"/>
                                <xsl:variable name="caption" select="parent::html:figure/html:figcaption/html:div[$position]"/>
                                <xsl:choose>
                                    <xsl:when test="not($caption)">
                                        <xsl:apply-templates select="."/>
                                    </xsl:when>
                                    <xsl:when test="$precede">
                                        <xsl:for-each select="parent::html:figure/html:figcaption/html:div[$position]">
                                            <caption>
                                                <xsl:call-template name="attlist.caption"/>
                                                <xsl:apply-templates select="node()"/>
                                            </caption>
                                        </xsl:for-each>
                                        <xsl:apply-templates select="."/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:apply-templates select="."/>
                                        <xsl:for-each select="parent::html:figure/html:figcaption/html:div[$position]">
                                            <caption>
                                                <xsl:call-template name="attlist.caption"/>
                                                <xsl:apply-templates select="node()"/>
                                            </caption>
                                        </xsl:for-each>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </imggroup>
    </xsl:template>

    <xsl:template name="attlist.imggroup">
        <xsl:call-template name="attrs"/>
    </xsl:template>

    <xsl:template match="html:p">
        <xsl:variable name="precedingemptyline" select="preceding-sibling::*[1] intersect preceding-sibling::html:hr[1]"/>
        <p>
            <xsl:call-template name="attlist.p">
                <xsl:with-param name="classes" select="if ($precedingemptyline) then 'precedingemptyline' else ()" tunnel="yes"/>
            </xsl:call-template>
            <xsl:apply-templates select="node()"/>
        </p>
    </xsl:template>

    <xsl:template name="attlist.p">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="'*'" tunnel="yes"/>
        </xsl:call-template>
        <xsl:call-template name="attlist.p.class"/>
    </xsl:template>

    <xsl:template name="attlist.p.class">
        <xsl:param name="classes" select="()" tunnel="yes"/>
        <xsl:variable name="classes"
            select="(for $class in ((tokenize(@class,'\s'),$classes)) return if ($class = ('part','jacketcopy','colophon','nonstandardpagination')) then $class else (), if (preceding-sibling::*[1] intersect preceding-sibling::html:hr[1]) then 'precedingemptyline' else ())"/>
        <xsl:if test="$classes">
            <xsl:attribute name="class" select="string-join($classes,' ')"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="html:hr"/>

    <xsl:template match="html:h1[f:types(.)='fulltitle' and parent::html:header[parent::html:body]]">
        <doctitle>
            <xsl:call-template name="attlist.doctitle"/>
            <xsl:apply-templates select="node()"/>
        </doctitle>
    </xsl:template>

    <xsl:template name="attlist.doctitle">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="'fulltitle'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="html:*[f:types(.)='z3998:author' and parent::html:header[parent::html:body]]">
        <docauthor>
            <xsl:call-template name="attlist.docauthor"/>
            <xsl:apply-templates select="node()"/>
        </docauthor>
    </xsl:template>

    <xsl:template name="attlist.docauthor">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="('author','docauthor')" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <!-- <covertitle> is not allowed in nordic DTBook. Using p instead. -->
    <xsl:template match="html:*[f:types(.)='z3998:covertitle' and parent::html:header[parent::html:body]]">
        <xsl:message select="'&lt;covertitle&gt; is not allowed in nordic DTBook, dropping it...'"/>
    </xsl:template>

    <!-- <covertitle> is not allowed in nordic DTBook. Using p instead with a "covertitle" class. -->
    <xsl:template name="attlist.covertitle">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="'*'" tunnel="yes"/>
            <!--            <xsl:with-param name="except-classes" select="'covertitle'" tunnel="yes"/>-->
        </xsl:call-template>
        <xsl:call-template name="attlist.p.class"/>
    </xsl:template>

    <xsl:template match="html:h1 | html:h2 | html:h3 | html:h4 | html:h5 | html:h6">
        <xsl:element name="h{f:level(.)}">
            <xsl:call-template name="attlist.h"/>
            <xsl:apply-templates select="node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template name="attlist.h">
        <xsl:call-template name="attrs"/>
    </xsl:template>

    <!-- <bridgehead> is not allowed in nordic DTBook. Using p instead. -->
    <xsl:template match="html:p[f:types(.)='bridgehead']">
        <xsl:message select="'&lt;bridgehead&gt; is not allowed in nordic DTBook. Using p instead with a bridgehead class.'"/>
        <p>
            <xsl:call-template name="attlist.bridgehead"/>
            <xsl:apply-templates select="node()"/>
        </p>
    </xsl:template>

    <!-- <bridgehead> is not allowed in nordic DTBook. Using p instead with a bridgehead class. -->
    <xsl:template name="attlist.bridgehead">
        <xsl:call-template name="attrs">
            <!--<xsl:with-param name="except-classes" select="'*'" tunnel="yes"/>-->
            <xsl:with-param name="classes" select="'bridgehead'" tunnel="yes"/>
        </xsl:call-template>
        <xsl:call-template name="attlist.p.class"/>
    </xsl:template>

    <xsl:template match="html:blockquote">
        <blockquote>
            <xsl:call-template name="attlist.blockquote"/>
            <xsl:apply-templates select="node()"/>
        </blockquote>
    </xsl:template>

    <xsl:template name="attlist.blockquote">
        <xsl:call-template name="attrs"/>
        <xsl:copy-of select="@cite"/>
    </xsl:template>

    <xsl:template match="html:dl">
        <dl>
            <xsl:call-template name="attlist.dl"/>
            <xsl:apply-templates select="node()"/>
        </dl>
    </xsl:template>

    <xsl:template name="attlist.dl">
        <xsl:call-template name="attrs"/>
    </xsl:template>

    <xsl:template match="html:dt">
        <dt>
            <xsl:call-template name="attlist.dt"/>
            <xsl:apply-templates select="node()"/>
        </dt>
    </xsl:template>

    <xsl:template name="attlist.dt">
        <xsl:call-template name="attrs"/>
    </xsl:template>

    <xsl:template match="html:dd">
        <dd>
            <xsl:call-template name="attlist.dd"/>
            <xsl:apply-templates select="node()"/>
        </dd>
    </xsl:template>

    <xsl:template name="attlist.dd">
        <xsl:call-template name="attrs"/>
    </xsl:template>

    <xsl:template match="html:ol | html:ul">
        <list>
            <xsl:call-template name="attlist.list"/>
            <xsl:apply-templates select="node()"/>
        </list>
    </xsl:template>

    <!-- Only 'pl' is allowed in nordic DTBook. -->
    <!--    <xsl:attribute name="type" select="if (self::html:ul) then 'ul' else if (f:classes(.)='list-preformatted') then 'pl' else 'ol'"/>-->
    <xsl:template name="attlist.list">
        <xsl:attribute name="type" select="'pl'"/>
        <xsl:call-template name="attrs"/>
        <xsl:copy-of select="@start"/>
        <xsl:if test="@type">
            <xsl:attribute name="enum" select="@type"/>
        </xsl:if>
        <xsl:attribute name="depth" select="count(ancestor::html:li)+1"/>
    </xsl:template>

    <!-- Only 'pl' is allowed in nordic DTBook; prepend "• " to all list items. -->
    <xsl:template match="html:li">
        <li>
            <xsl:call-template name="attlist.li"/>
            <xsl:text>• </xsl:text>
            <xsl:apply-templates select="node()"/>
        </li>
    </xsl:template>

    <xsl:template name="attlist.li">
        <xsl:call-template name="attrs"/>
    </xsl:template>

    <xsl:template match="html:span[f:classes(.)='lic']">
        <lic>
            <xsl:call-template name="attlist.lic"/>
            <xsl:apply-templates select="node()"/>
        </lic>
    </xsl:template>

    <xsl:template name="attlist.lic">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="'lic'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="cellhvalign">
        <!--
            the @cellhalign and @cellvalign attributes could potentially be inferred from the CSS here,
            but it's probably not worth it so they are ignored for now.
        -->
    </xsl:template>

    <xsl:template match="html:table">
        <table>
            <xsl:call-template name="attlist.table"/>
            <xsl:for-each select="html:caption">
                <xsl:call-template name="caption.table"/>
            </xsl:for-each>
            <xsl:apply-templates select="html:colgroup"/>

            <xsl:apply-templates select="html:thead/html:tr"/>
            <xsl:apply-templates select="html:tbody/html:tr | html:tr"/>
            <xsl:apply-templates select="html:tfoot/html:tr"/>

            <!--<xsl:apply-templates select="html:thead"/>
            <xsl:apply-templates select="html:tfoot"/>
            <xsl:apply-templates select="html:tbody | html:tr"/>-->
        </table>
    </xsl:template>

    <xsl:template name="attlist.table">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="for $class in (f:classes(.)) return if (starts-with($class,'table-rules') or starts-with($class,'table-frame-')) then $class else ()"
                tunnel="yes"/>
        </xsl:call-template>
        <xsl:if test="html:caption/html:p[f:classes(.)='table-summary']">
            <xsl:attribute name="summary" select="normalize-space(string-join(html:caption/html:p[f:classes(.)='table-summary']//text(),' '))"/>
        </xsl:if>
        <xsl:if test="count(f:classes(.)[matches(.,'^table-rules-')])">
            <xsl:attribute name="rules" select="replace(f:classes(.)[matches(.,'^table-rules-')][1],'^table-rules-','')"/>
        </xsl:if>
        <xsl:if test="count(f:classes(.)[matches(.,'^table-frame-')])">
            <xsl:attribute name="frame" select="replace(f:classes(.)[matches(.,'^table-frame-')][1],'^table-frame-','')"/>
        </xsl:if>
        <!--
            @cellspacing, @cellpadding and @width could potentially be inferred from the CSS,
            but it's probably not worth it so they are ignored for now
        -->
    </xsl:template>

    <xsl:template name="caption.table">
        <xsl:variable name="content" select="node()[not(self::html:p[f:classes(.)='table-summary'])]"/>
        <xsl:if test="$content">
            <caption>
                <xsl:call-template name="attlist.caption"/>
                <xsl:apply-templates select="$content"/>
            </caption>
        </xsl:if>
    </xsl:template>

    <xsl:template match="html:figcaption">
        <xsl:variable name="content" select="node()[not(self::div[f:classes(.)='img-caption'])]"/>
        <xsl:if test="$content">
            <caption>
                <xsl:call-template name="attlist.caption"/>
                <xsl:apply-templates select="$content"/>
            </caption>
        </xsl:if>
    </xsl:template>

    <!--<xsl:template match="html:div[f:classes(.)='img-caption']">
        <caption>
            <xsl:call-template name="attlist.caption"/>
            <xsl:apply-templates select="node()"/>
        </caption>
    </xsl:template>-->

    <xsl:template name="attlist.caption">
        <xsl:call-template name="attrs">
            <xsl:with-param name="except-classes" select="'img-caption'" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="html:thead">
        <thead>
            <xsl:call-template name="attlist.thead"/>
            <xsl:apply-templates select="node()"/>
        </thead>
    </xsl:template>

    <xsl:template name="attlist.thead">
        <xsl:call-template name="attrs"/>
        <xsl:call-template name="cellhvalign"/>
    </xsl:template>

    <xsl:template match="html:tfoot">
        <tfoot>
            <xsl:call-template name="attlist.tfoot"/>
            <xsl:apply-templates select="node()"/>
        </tfoot>
    </xsl:template>

    <xsl:template name="attlist.tfoot">
        <xsl:call-template name="attrs"/>
        <xsl:call-template name="cellhvalign"/>
    </xsl:template>

    <xsl:template match="html:tbody">
        <tbody>
            <xsl:call-template name="attlist.tbody"/>
            <xsl:apply-templates select="node()"/>
        </tbody>
    </xsl:template>

    <xsl:template name="attlist.tbody">
        <xsl:call-template name="attrs"/>
        <xsl:call-template name="cellhvalign"/>
    </xsl:template>

    <!-- <colgroup> is not allowed in nordic DTBook. -->
    <xsl:template match="html:colgroup">
        <xsl:message select="'&lt;colgroup&gt; is not allowed in nordic DTBook.'"/>
        <!--<colgroup>
            <xsl:call-template name="attlist.colgroup"/>
            <xsl:apply-templates select="node()"/>
        </colgroup>-->
    </xsl:template>

    <xsl:template name="attlist.colgroup">
        <xsl:call-template name="attrs"/>
        <xsl:copy-of select="@span"/>
        <xsl:call-template name="cellhvalign"/>
        <!--
            @width could potentially be inferred from the CSS,
            but it's probably not worth it so they are ignored for now
        -->
    </xsl:template>

    <!-- <col> is not allowed in nordic DTBook. -->
    <xsl:template match="html:col">
        <xsl:message select="'&lt;col&gt; is not allowed in nordic DTBook.'"/>
        <!--<col>
            <xsl:call-template name="attlist.col"/>
            <xsl:apply-templates select="node()"/>
        </col>-->
    </xsl:template>

    <xsl:template name="attlist.col">
        <xsl:call-template name="attrs"/>
        <xsl:copy-of select="@span"/>
        <xsl:call-template name="cellhvalign"/>
        <!--
            @width could potentially be inferred from the CSS,
            but it's probably not worth it so they are ignored for now
        -->
    </xsl:template>

    <xsl:template match="html:tr">
        <tr>
            <xsl:call-template name="attlist.tr"/>
            <xsl:apply-templates select="node()"/>
        </tr>
    </xsl:template>

    <xsl:template name="attlist.tr">
        <xsl:call-template name="attrs"/>
        <xsl:call-template name="cellhvalign"/>
        <!--
            @width could potentially be inferred from the CSS,
            but it's probably not worth it so they are ignored for now
        -->
    </xsl:template>

    <xsl:template match="html:th">
        <th>
            <xsl:call-template name="attlist.th"/>
            <xsl:apply-templates select="node()"/>
        </th>
    </xsl:template>

    <xsl:template name="attlist.th">
        <xsl:call-template name="attrs"/>
        <xsl:copy-of select="@headers|@scope|@rowspan|@colspan"/>
        <xsl:call-template name="cellhvalign"/>
    </xsl:template>

    <xsl:template match="html:td">
        <td>
            <xsl:call-template name="attlist.td"/>
            <xsl:apply-templates select="node()"/>
        </td>
    </xsl:template>

    <xsl:template name="attlist.td">
        <xsl:call-template name="attrs"/>
        <xsl:copy-of select="@headers|@scope|@rowspan|@colspan"/>
        <xsl:call-template name="cellhvalign"/>
    </xsl:template>

    <xsl:template name="copy-preceding-comments">
        <xsl:variable name="this" select="."/>
        <xsl:apply-templates select="preceding-sibling::comment()[not($this/preceding-sibling::*) or preceding-sibling::*[1] is $this/preceding-sibling::*[1]]"/>
    </xsl:template>

    <xsl:function name="f:types" as="xs:string*">
        <xsl:param name="element" as="element()"/>
        <xsl:sequence select="tokenize($element/@epub:type,'\s+')"/>
    </xsl:function>

    <xsl:function name="f:classes" as="xs:string*">
        <xsl:param name="element" as="element()"/>
        <xsl:sequence select="tokenize($element/@class,'\s+')"/>
    </xsl:function>

    <xsl:function name="f:level" as="xs:integer">
        <xsl:param name="element" as="element()"/>
        <xsl:variable name="level" select="($element/ancestor-or-self::html:*[self::html:section or self::html:article or self::html:aside or self::html:nav or self::html:body])[last()]"/>
        <xsl:variable name="level-nodes" select="f:level-nodes($level)"/>
        <xsl:variable name="h-in-section" select="$level-nodes[self::html:h1 or self::html:h2 or self::html:h3 or self::html:h4 or self::html:h5 or self::html:h6]"/>
        <xsl:variable name="h" select="$h-in-section[1]"/>
        <xsl:variable name="sections" select="$level/ancestor-or-self::*[self::html:section or self::html:article or self::html:aside or self::html:nav]"/>
        <xsl:variable name="explicit-level" select="count($sections)-1"/>
        <xsl:variable name="h-in-level-numbers" select="if ($h-in-section) then reverse($h-in-section/xs:integer(number(replace(local-name(),'^h','')))) else 1"/>
        <xsl:variable name="implicit-level" select="if ($h-in-level-numbers[1] = 6) then 6 else ()"/>
        <xsl:variable name="h-in-level-numbers" select="$h-in-level-numbers[not(.=6)]"/>
        <xsl:variable name="implicit-level" select="($implicit-level, if ($h-in-level-numbers[1] = 5) then 5 else ())"/>
        <xsl:variable name="h-in-level-numbers" select="$h-in-level-numbers[not(.=5)]"/>
        <xsl:variable name="implicit-level" select="($implicit-level, if ($h-in-level-numbers[1] = 4) then 4 else ())"/>
        <xsl:variable name="h-in-level-numbers" select="$h-in-level-numbers[not(.=4)]"/>
        <xsl:variable name="implicit-level" select="($implicit-level, if ($h-in-level-numbers[1] = 3) then 3 else ())"/>
        <xsl:variable name="h-in-level-numbers" select="$h-in-level-numbers[not(.=3)]"/>
        <xsl:variable name="implicit-level" select="($implicit-level, if ($h-in-level-numbers[1] = 2) then 2 else ())"/>
        <xsl:variable name="implicit-level" select="($implicit-level, if ($h-in-level-numbers = 1) then 1 else ())"/>
        <xsl:variable name="implicit-level" select="count($implicit-level)"/>

        <xsl:variable name="level" select="$explicit-level + $implicit-level"/>
        <xsl:sequence select="max((1,min(($level, 6))))"/>
        <!--
            NOTE: DTBook only supports 6 levels when using the explicit level1-level6 / h1-h6 elements,
            so min(($level, 6)) is used to flatten deeper structures.
            The implicit level / hd elements could be used in cases where the structures are deeper.
            However, our tools would have to support those elements.
        -->
    </xsl:function>

    <xsl:function name="f:level-nodes" as="node()*">
        <xsl:param name="level" as="element()"/>
        <xsl:variable name="level-levels"
            select="$level//html:*[(self::html:section or self::html:article or self::html:aside or self::html:nav or self::html:body) and ((ancestor::html:*[self::html:section or self::html:article or self::html:aside or self::html:nav or self::html:body])[last()] intersect $level)]"/>
        <xsl:variable name="level-nodes" select="$level//node()[not(ancestor-or-self::* intersect $level-levels)]"/>
        <xsl:sequence select="$level-nodes"/>
    </xsl:function>

    <xsl:function name="f:generate-pretty-id" as="xs:string">
        <xsl:param name="element" as="element()"/>
        <xsl:variable name="id">
            <xsl:choose>
                <xsl:when test="$element[self::html:blockquote or self::html:q]">
                    <xsl:sequence select="concat('quote_',count($element/preceding::*[self::html:blockquote or self::html:q])+1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="element-name" select="local-name($element)"/>
                    <xsl:sequence select="concat($element-name,'_',count($element/preceding::*[local-name()=$element-name])+1)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="if ($all-ids=$id) then generate-id($element) else $id"/>
    </xsl:function>

</xsl:stylesheet>
