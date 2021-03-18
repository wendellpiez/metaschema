# XML Lint

CL utility for basic XML parsing/validation tasks
(*not* transformations)

## Installation --

On many Macs or Unixes, it's already installed.

test with `xmllint --help`

Ubuntu:
```
$ apt-get install libxml2-utils
```

Chocolatey:
```
> choco install xsltproc
```

## Use --

Then to validate an XML with an XSD:

```
$ xmllint --noout --schema schema.xsd xml-file.xml-file
```

Here:
  * `-- noout` says don't echo the file to STDOUT
  * `-- schema schema.xsd` identifies the schema to be used
  * `xml-file.xml` identifies the XML to be validated

On line, try https://xmllint.com/

Also xmllint has a shell ... https://www.tutorialspoint.com/unix_commands/xmllint.htm

## Help

```
$ xmllint --help
```

